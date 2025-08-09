import SwiftUI
import UIKit

struct BadgeConfigurationView: View {
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var selectedFields: Set<BadgeField> = []
    @State private var templateImage: UIImage? = nil
    @State private var regions: [String: NormalizedRect] = [:]
    @State private var showingScanner = false
    @State private var showingRegionEditor = false
    @State private var showingFullImage = false
    @State private var ocrPreview: [String: String] = [:]
    @State private var isOCRRunning = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Badge Fields") { badgeFieldsGrid }
                Section("Template") { templateSection }
                Section("Preview") { badgePreview }
            }
            .navigationTitle("Configure Badge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let ordered = BadgeField.allCases.filter { selectedFields.contains($0) }
                        event.badgeFieldKeys = ordered.map { $0.rawValue }
                        // Persist template image and regions
                        if let img = templateImage, let data = img.jpegData(compressionQuality: 0.85) {
                            event.badgeTemplateImageData = data
                        }
                        // Replace badgeRegions with current selections
                        event.badgeRegions = regions.compactMap { key, rect in
                            guard let field = BadgeField(rawValue: key), selectedFields.contains(field) else { return nil }
                            return BadgeRegion(fieldKey: key, rect: rect)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                let current = Set(event.badgeFieldKeys.compactMap(BadgeField.init(rawValue:)))
                if current.isEmpty {
                    selectedFields = Set(BadgeField.defaultSelection)
                } else {
                    selectedFields = current
                }
                if let data = event.badgeTemplateImageData, let img = UIImage(data: data) {
                    templateImage = img
                }
                regions = event.badgeFieldRegionsMap
                updatePreviewOCR()
            }
            .fullScreenCover(isPresented: $showingRegionEditor) {
                if let image = templateImage {
                    RegionEditorView(image: image, fields: Array(selectedFields), regions: $regions)
                }
            }
            .fullScreenCover(isPresented: $showingFullImage) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let image = templateImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
                }
                .onTapGesture { showingFullImage = false }
            }
        }
    }

    private var badgeFieldsGrid: some View {
        let columns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(BadgeField.allCases) { field in
                let isOn = selectedFields.contains(field)
                Button { toggle(field, isOn: isOn) } label: {
                    BadgeFieldChip(title: field.displayName, selected: isOn)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggle(_ field: BadgeField, isOn: Bool) {
        if isOn { selectedFields.remove(field) } else { selectedFields.insert(field) }
    }

    private var badgePreview: some View {
        Group {
            if let image = templateImage, regions.isEmpty {
                // Show the scanned badge until regions are defined
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
            } else if !regions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Extracted from Template").font(.headline)
                        if isOCRRunning { ProgressView().scaleEffect(0.8) }
                    }
                    let ordered = BadgeField.allCases.filter { selectedFields.contains($0) }
                    if ordered.isEmpty {
                        Text("No fields selected").foregroundStyle(.secondary)
                    } else {
                        ForEach(ordered) { field in
                            let value = (ocrPreview[field.rawValue] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            if !value.isEmpty {
                                LabeledContent(field.displayName, value: value)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    VStack(spacing: 8) {
                        Text("Conference Badge").font(.headline)
                        ForEach(BadgeField.allCases.filter { selectedFields.contains($0) }) { field in
                            Text(field.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if selectedFields.isEmpty {
                            Text("No fields selected").foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = templateImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .onTapGesture { showingFullImage = true }
            } else {
                VStack(spacing: 12) {
                    Text("No template image, please scan using the button below")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    HStack { Spacer()
                        Button { showingScanner = true } label: {
                            Label("Scan", systemImage: "doc.viewfinder")
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer() }
                }
            }
            if templateImage != nil {
                HStack(spacing: 12) {
                    Button { showingScanner = true } label: { Label("Re-Scan", systemImage: "doc.viewfinder") }
                        .buttonStyle(.bordered)

                    Button { showingRegionEditor = true } label: { Label("Format", systemImage: "rectangle.dashed.badge.record") }
                        .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        templateImage = nil
                        regions.removeAll()
                        ocrPreview.removeAll()
                    } label: { Label("Remove", systemImage: "trash") }
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            // For template capture we want the full page without any perspective crop.
            DocumentScannerView(onScanned: { image, _ in
                // Image is already preprocessed by DocumentScannerView
                templateImage = image
                showingScanner = false
                updatePreviewOCR()
            }, onCancel: {
                showingScanner = false
            }, enablePerspectiveCorrection: false)
            .ignoresSafeArea()
        }
        .onChange(of: regions) { _, _ in updatePreviewOCR() }
        .onChange(of: templateImage) { _, _ in updatePreviewOCR() }
    }

    private func updatePreviewOCR() {
        guard let image = templateImage, !regions.isEmpty else {
            ocrPreview = [:]
            return
        }
        isOCRRunning = true
        OCRProcessor.recognizeText(in: image, regionsByKey: regions) { mapped in
            self.ocrPreview = mapped
            self.isOCRRunning = false
        }
    }
}

private struct BadgeFieldChip: View {
    let title: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: selected ? "checkmark.seal.fill" : "seal")
            Text(title)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        .foregroundStyle(selected ? Color.accentColor : .primary)
        .clipShape(Capsule())
    }
}


