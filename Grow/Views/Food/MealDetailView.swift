import SwiftUI
import WebKit

struct MealDetailView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @EnvironmentObject private var userModel: UserDataModel
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    let sourceDate: Date?

    @State private var mealName = ""
    @State private var showAddProductToMeal = false
    @State private var showRecipeBrowser = false
    @State private var parsedRecipePreview: ParsedRecipe?
    @State private var isParsingRecipe = false
    @State private var isImportingRecipe = false
    @State private var isSavingMeal = false
    @State private var importErrorMessage: String?
    @State private var showCopyCalendar = false
    @State private var copyDate = Date()
    @State private var mealToSave: Meal?
    @State private var showSaveAsMeal = false
    @State private var showDeleteConfirmation = false
    @State private var showShareWithFamily = false

    init(meal: Meal, sourceDate: Date? = nil) {
        self.meal = meal
        self.sourceDate = sourceDate
    }

    private var currentMeal: Meal {
        foodModel.currentMeal(for: meal) ?? meal
    }

    private var displayedMealName: String {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }

        let currentName = currentMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return currentName.isEmpty ? "Maaltijd" : currentName
    }

    private var canSaveAsMeal: Bool {
        !foodModel.isSavedMeal(currentMeal)
    }

    var body: some View {
        ZStack {
            List {
                if let recipe = currentMeal.recipe {
                    Section {
                        MealRecipeHero(recipe: recipe)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                }

                if currentMeal.recipe == nil {
                    Section("Titel") {
                        TextField("Maaltijdnaam", text: $mealName)
                            .onSubmit {
                                persistMealName()
                            }
                    }
                }

                Section("Ingredienten") {
                    if let products = currentMeal.products, !products.isEmpty {
                        ForEach(products, id: \.self) { product in
                            FoodProductRow(meal: currentMeal, product: product)
                        }
                        .onDelete(perform: deleteProduct)
                    } else {
                        ContentUnavailableView(
                            "Nog geen ingredienten",
                            systemImage: "fork.knife",
                            description: Text("Voeg producten toe om deze maaltijd op te slaan of bij te werken.")
                        )
                    }

                    Button {
                        showAddProductToMeal = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Voeg product toe")
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                Section("Totaal") {
                    MealMacroSummaryRow(title: "Calorieën", value: NumberHelper.roundedNumbersFromDouble(unit: currentMeal.kcal))
                    MealMacroSummaryRow(title: "Koolhydraten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.carbs))
                    MealMacroSummaryRow(title: "Eiwitten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.protein))
                    MealMacroSummaryRow(title: "Vetten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.fat))
                    MealMacroSummaryRow(title: "Vezels", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.fiber))
                }

                Section("Bereiding") {
                    if let recipe = currentMeal.recipe {
                        MealRecipeCard(recipe: recipe)
                    } else {
                        ContentUnavailableView(
                            "Nog geen recept",
                            systemImage: "book.closed",
                            description: Text("Importeer een receptpagina met Recipe structured data.")
                        )
                        
                        Button {
                            showRecipeBrowser = true
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                Text("Importeer recept")
                            }
                        }
                    }

                    if isParsingRecipe || isImportingRecipe {
                        HStack {
                            ProgressView()
                            Text(isImportingRecipe ? "Recept opslaan..." : "Recept analyseren...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if showCopyCalendar {
                MealCopyCalendar(enableSheet: $showCopyCalendar, date: $copyDate, mealToCopy: currentMeal)
            }
        }
        .navigationDestination(isPresented: $showAddProductToMeal) {
            AddProductToMealList(meal: currentMeal, isPresented: $showAddProductToMeal)
        }
        .sheet(isPresented: $showSaveAsMeal) {
            NavigationStack {
                if let mealToSave {
                    SaveAsMeal(meal: mealToSave)
                }
            }
        }
        .sheet(isPresented: $showRecipeBrowser) {
            RecipeBrowserSheet { confirmedURL in
                showRecipeBrowser = false
                Task {
                    await loadRecipePreview(from: confirmedURL)
                }
            }
        }
        .sheet(isPresented: $showShareWithFamily) {
            NavigationStack {
                ShareMealWithFamilySheet(
                    familyMembers: userModel.familyMembers,
                    onSelect: { member in
                        foodModel.shareMealWithFamily(
                            meal: currentMeal,
                            otherUserID: member.userID,
                            sourceDate: sourceDate ?? foodModel.date
                        ) { success in
                            if success {
                                showShareWithFamily = false
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: recipePreviewBinding) {
            if let parsedRecipePreview {
                RecipeImportPreviewSheet(
                    recipe: parsedRecipePreview,
                    isImporting: isImportingRecipe,
                    onImport: {
                        Task {
                            await importRecipe(parsedRecipePreview)
                        }
                    }
                )
            }
        }
        .alert("Recept importeren mislukt", isPresented: importErrorBinding) {
            Button("Ok", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? "Er ging iets mis.")
        }
        .alert("Maaltijd delen mislukt", isPresented: shareMealErrorBinding) {
            Button("Ok", role: .cancel) {
                foodModel.shareMealErrorMessage = nil
            }
        } message: {
            Text(foodModel.shareMealErrorMessage ?? "Er ging iets mis.")
        }
        .alert("Maaltijd gedeeld", isPresented: shareMealSuccessBinding) {
            Button("Ok", role: .cancel) {
                foodModel.shareMealSuccessMessage = nil
            }
        } message: {
            Text(foodModel.shareMealSuccessMessage ?? "De maaltijd is gedeeld.")
        }
        .alert("Verwijder maaltijd?", isPresented: $showDeleteConfirmation) {
            Button("Annuleer", role: .cancel) {}
            Button("Verwijder", role: .destructive) {
                foodModel.removeMeal(for: currentMeal)
                dismiss()
            }
        } message: {
            Text("Deze maaltijd wordt verwijderd uit je food diary.")
        }
        .listStyle(.insetGrouped)
        .navigationTitle(displayedMealName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if canSaveAsMeal {
                        Button {
                            mealToSave = currentMeal
                            showSaveAsMeal = true
                        } label: {
                            Label("Sla maaltijd op", systemImage: "square.and.arrow.down")
                        }
                    }

                    Button {
                        copyDate = foodModel.date
                        showCopyCalendar = true
                    } label: {
                        Label("Kopieer", systemImage: "doc.on.doc")
                    }

                    if userModel.familyMembers.isEmpty == false {
                        Button {
                            showShareWithFamily = true
                        } label: {
                            Label("Deel met familie", systemImage: "person.2")
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Verwijder", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            mealName = currentMeal.name ?? ""
        }
        .onDisappear {
            persistMealName()
        }
    }

    private var recipePreviewBinding: Binding<Bool> {
        Binding(
            get: { parsedRecipePreview != nil },
            set: { isPresented in
                if !isPresented {
                    parsedRecipePreview = nil
                }
            }
        )
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )
    }

    private var shareMealErrorBinding: Binding<Bool> {
        Binding(
            get: { foodModel.shareMealErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    foodModel.shareMealErrorMessage = nil
                }
            }
        )
    }

    private var shareMealSuccessBinding: Binding<Bool> {
        Binding(
            get: { foodModel.shareMealSuccessMessage != nil },
            set: { isPresented in
                if !isPresented {
                    foodModel.shareMealSuccessMessage = nil
                }
            }
        )
    }

    private func persistMealName() {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = currentMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard trimmedName != currentName else {
            return
        }

        foodModel.updateMealName(for: meal, name: trimmedName)
    }

    private func deleteProduct(at offsets: IndexSet) {
        guard let productIndex = offsets.first else {
            return
        }

        foodModel.deleteProductFromMeal(for: currentMeal, with: productIndex)
    }

    @MainActor
    private func loadRecipePreview(from url: URL) async {
        isParsingRecipe = true
        defer { isParsingRecipe = false }

        do {
            parsedRecipePreview = try await RecipeStructuredDataImporter.parseRecipe(from: url)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func importRecipe(_ recipe: ParsedRecipe) async {
        isImportingRecipe = true
        defer { isImportingRecipe = false }

        do {
            try await foodModel.importMealRecipe(recipe, for: currentMeal)
            parsedRecipePreview = nil
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

private struct MealMacroSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ShareMealWithFamilySheet: View {
    let familyMembers: [FamilyMember]
    let onSelect: (FamilyMember) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(familyMembers, id: \.stableIdentifier) { member in
                Button {
                    onSelect(member)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.resolvedDisplayName)
                                .foregroundStyle(Color.primary)
                            if let email = member.email,
                               email != member.resolvedDisplayName {
                                Text(email)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Text(member.status.displayName)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Deel met familie")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Sluit") {
                    dismiss()
                }
            }
        }
    }
}

private struct MealRecipeHero: View {
    let recipe: MealRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURLString = recipe.imageStorageURL ?? recipe.imageSourceURL,
               let imageURL = URL(string: imageURLString) {
                ZStack(alignment: .bottom) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            ZStack {
                                Rectangle().fill(Color.secondary.opacity(0.12))
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    LinearGradient(
                        colors: [
                            .clear,
                            Color(.systemBackground).opacity(0.35),
                            Color(.systemBackground).opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 110)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .allowsHitTesting(false)
                }
            }

            Text(recipe.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            if let totalTimeText = recipe.totalTimeText, !totalTimeText.isEmpty {
                Label(totalTimeText, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }
        }
    }
}

private struct MealRecipeCard: View {
    let recipe: MealRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let sourceURL = URL(string: recipe.sourceURL) {
                Link(destination: sourceURL) {
                    Label(recipe.sourceDomain, systemImage: "link")
                        .font(.subheadline)
                }
            }

            if !recipe.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                            Text(instruction)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RecipeImportPreviewSheet: View {
    let recipe: ParsedRecipe
    let isImporting: Bool
    let onImport: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageURL = recipe.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                ZStack {
                                    Rectangle().fill(Color.secondary.opacity(0.12))
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    Text(recipe.title)
                        .font(.title3.weight(.bold))

                    Link(destination: recipe.sourceURL) {
                        Label(recipe.sourceURL.host ?? recipe.sourceURL.absoluteString, systemImage: "link")
                    }

                    if let totalTimeText = recipe.totalTimeText, !totalTimeText.isEmpty {
                        Label(totalTimeText, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !recipe.ingredients.isEmpty {
                        Divider()

                        Text("Ingrediënten")
                            .font(.headline)

                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    Text("Bereiding")
                        .font(.headline)

                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                            Text(instruction)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recept preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isImporting ? "Bezig..." : "Importeer") {
                        onImport()
                    }
                    .disabled(isImporting)
                }
            }
        }
    }
}

private struct RecipeBrowserSheet: View {
    let onConfirmPage: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var loadedURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("URL of zoekopdracht", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    Button("Ga") {
                        loadedURL = resolvedURL(from: query)
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)

                RecipeWebView(url: loadedURL, currentURL: $loadedURL)
            }
            .navigationTitle("Zoek recept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Gebruik deze pagina") {
                        if let loadedURL {
                            onConfirmPage(loadedURL)
                        }
                    }
                    .disabled(loadedURL == nil)
                }
            }
        }
    }

    private func resolvedURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        if let httpsURL = URL(string: "https://\(trimmed)"), httpsURL.host != nil {
            return httpsURL
        }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}

private struct RecipeWebView: UIViewRepresentable {
    let url: URL?
    @Binding var currentURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(currentURL: $currentURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else {
            return
        }

        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var currentURL: URL?

        init(currentURL: Binding<URL?>) {
            _currentURL = currentURL
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            currentURL = webView.url
        }
    }
}

private enum RecipeStructuredDataImporter {
    enum ImportError: LocalizedError {
        case noRecipeStructuredData
        case invalidResponseEncoding

        var errorDescription: String? {
            switch self {
            case .noRecipeStructuredData:
                return "Op deze pagina is geen Recipe structured data gevonden."
            case .invalidResponseEncoding:
                return "De webpagina kon niet goed worden gelezen."
            }
        }
    }

    static func parseRecipe(from url: URL) async throws -> ParsedRecipe {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard
            let html = String(data: data, encoding: .utf8) ??
                String(data: data, encoding: .isoLatin1)
        else {
            throw ImportError.invalidResponseEncoding
        }

        for script in recipeJSONLDBlocks(in: html) {
            if let recipe = try parseRecipe(fromJSONLD: script, sourceURL: url) {
                return recipe
            }
        }

        throw ImportError.noRecipeStructuredData
    }

    private static func recipeJSONLDBlocks(in html: String) -> [String] {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, options: [], range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: html) else {
                return nil
            }

            return html[range]
                .replacingOccurrences(of: "<!--", with: "")
                .replacingOccurrences(of: "-->", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func parseRecipe(fromJSONLD json: String, sourceURL: URL) throws -> ParsedRecipe? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }

        let object = try JSONSerialization.jsonObject(with: data)
        let recipes = recipeObjects(in: object)

        for recipe in recipes {
            if let parsed = parsedRecipe(from: recipe, sourceURL: sourceURL) {
                return parsed
            }
        }

        return nil
    }

    private static func recipeObjects(in value: Any) -> [[String: Any]] {
        if let dictionary = value as? [String: Any] {
            var results = [[String: Any]]()

            if isRecipe(dictionary) {
                results.append(dictionary)
            }

            if let graph = dictionary["@graph"] {
                results.append(contentsOf: recipeObjects(in: graph))
            }

            if let itemListElement = dictionary["itemListElement"] {
                results.append(contentsOf: recipeObjects(in: itemListElement))
            }

            return results
        }

        if let array = value as? [Any] {
            return array.flatMap { recipeObjects(in: $0) }
        }

        return []
    }

    private static func isRecipe(_ dictionary: [String: Any]) -> Bool {
        if let type = dictionary["@type"] as? String {
            return type.localizedCaseInsensitiveContains("Recipe")
        }

        if let types = dictionary["@type"] as? [String] {
            return types.contains { $0.localizedCaseInsensitiveContains("Recipe") }
        }

        return false
    }

    private static func parsedRecipe(from dictionary: [String: Any], sourceURL: URL) -> ParsedRecipe? {
        guard
            let title = dictionary["name"] as? String,
            !sanitizedText(from: title).isEmpty
        else {
            return nil
        }

        let instructions = parseInstructions(from: dictionary["recipeInstructions"])
        guard !instructions.isEmpty else {
            return nil
        }

        let yieldInfo = parseYieldInfo(from: dictionary["recipeYield"])

        return ParsedRecipe(
            sourceURL: sourceURL,
            title: sanitizedText(from: title),
            imageURL: parseImageURL(from: dictionary["image"], baseURL: sourceURL),
            yieldText: yieldInfo.text,
            servingsCount: yieldInfo.servingsCount,
            totalTimeText: parseTotalTime(from: dictionary),
            ingredients: parseIngredients(
                from: dictionary["recipeIngredient"] ?? dictionary["ingredients"],
                servingsCount: yieldInfo.servingsCount
            ),
            instructions: instructions
        )
    }

    private static func parseImageURL(from value: Any?, baseURL: URL) -> URL? {
        if let string = value as? String {
            return URL(string: string, relativeTo: baseURL)?.absoluteURL
        }

        if let array = value as? [Any] {
            for item in array {
                if let url = parseImageURL(from: item, baseURL: baseURL) {
                    return url
                }
            }
        }

        if let dictionary = value as? [String: Any] {
            if let string = dictionary["url"] as? String {
                return URL(string: string, relativeTo: baseURL)?.absoluteURL
            }
        }

        return nil
    }

    private static func parseInstructions(from value: Any?) -> [String] {
        if let string = value as? String {
            let sanitized = sanitizedText(from: string)
            return sanitized.isEmpty ? [] : [sanitized]
        }

        if let array = value as? [Any] {
            return array.flatMap { item in
                if let string = item as? String {
                    let sanitized = sanitizedText(from: string)
                    return sanitized.isEmpty ? [] : [sanitized]
                }

                if let dictionary = item as? [String: Any] {
                    if let text = dictionary["text"] as? String {
                        let sanitized = sanitizedText(from: text)
                        return sanitized.isEmpty ? [] : [sanitized]
                    }

                    if let nested = dictionary["itemListElement"] {
                        return parseInstructions(from: nested)
                    }
                }

                return []
            }
        }

        return []
    }

    private static func parseIngredients(from value: Any?, servingsCount: Double?) -> [String] {
        if let string = value as? String {
            let sanitized = sanitizedText(from: string)
            let normalized = normalizedIngredientAmount(from: sanitized, servingsCount: servingsCount)
            return normalized.isEmpty ? [] : [normalized]
        }

        if let array = value as? [Any] {
            return array.compactMap { item in
                if let string = item as? String {
                    let sanitized = sanitizedText(from: string)
                    let normalized = normalizedIngredientAmount(from: sanitized, servingsCount: servingsCount)
                    return normalized.isEmpty ? nil : normalized
                }

                if let dictionary = item as? [String: Any],
                   let text = dictionary["text"] as? String {
                    let sanitized = sanitizedText(from: text)
                    let normalized = normalizedIngredientAmount(from: sanitized, servingsCount: servingsCount)
                    return normalized.isEmpty ? nil : normalized
                }

                return nil
            }
        }

        return []
    }

    private static func parseTotalTime(from dictionary: [String: Any]) -> String? {
        let candidates = [
            dictionary["totalTime"],
            dictionary["cookTime"],
            dictionary["prepTime"]
        ]

        for candidate in candidates {
            if let string = candidate as? String,
               let formatted = formattedDuration(from: string) {
                return formatted
            }
        }

        return nil
    }

    private static func parseYieldInfo(from value: Any?) -> (text: String?, servingsCount: Double?) {
        if let number = value as? NSNumber {
            return (text: number.stringValue, servingsCount: number.doubleValue > 0 ? number.doubleValue : nil)
        }

        if let string = value as? String {
            let sanitized = sanitizedText(from: string)
            return (
                text: sanitized.isEmpty ? nil : sanitized,
                servingsCount: firstNumericValue(in: sanitized)
            )
        }

        if let array = value as? [Any] {
            for item in array {
                let parsed = parseYieldInfo(from: item)
                if parsed.text != nil || parsed.servingsCount != nil {
                    return parsed
                }
            }
        }

        if let dictionary = value as? [String: Any] {
            if let text = dictionary["text"] as? String {
                let sanitized = sanitizedText(from: text)
                return (
                    text: sanitized.isEmpty ? nil : sanitized,
                    servingsCount: firstNumericValue(in: sanitized)
                )
            }
        }

        return (nil, nil)
    }

    private static func normalizedIngredientAmount(from text: String, servingsCount: Double?) -> String {
        guard let servingsCount, servingsCount > 0 else {
            return text
        }

        let pattern = #"(?i)\b(\d+(?:[.,]\d+)?)\s*(kg|gram|gr|g|liter|l|ml|milliliter)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let amountRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text) else {
            return text
        }

        let amountText = text[amountRange].replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(amountText) else {
            return text
        }

        let unit = text[unitRange].lowercased()
        let baseAmount: Double
        let displayUnit: String

        switch unit {
        case "kg":
            baseAmount = amount * 1000
            displayUnit = "g"
        case "liter", "l":
            baseAmount = amount * 1000
            displayUnit = "ml"
        case "gram", "gr", "g":
            baseAmount = amount
            displayUnit = "g"
        case "ml", "milliliter":
            baseAmount = amount
            displayUnit = "ml"
        default:
            return text
        }

        let normalizedAmount = baseAmount / servingsCount
        let formattedAmount = formattedIngredientAmount(normalizedAmount)
        let fullMatchRange = Range(match.range, in: text)!
        return text.replacingCharacters(in: fullMatchRange, with: "\(formattedAmount) \(displayUnit)")
    }

    private static func formattedIngredientAmount(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == floor(rounded) {
            return String(Int(rounded))
        }

        return String(rounded).replacingOccurrences(of: ".", with: ",")
    }

    private static func firstNumericValue(in text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        let pattern = #"\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)),
              let range = Range(match.range, in: normalized) else {
            return nil
        }

        return Double(normalized[range])
    }

    private static func formattedDuration(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let hoursMatch = trimmed.range(of: #"(\d+)H"#, options: .regularExpression),
           let minutesMatch = trimmed.range(of: #"(\d+)M"#, options: .regularExpression) {
            let hours = trimmed[hoursMatch].replacingOccurrences(of: "H", with: "").replacingOccurrences(of: "PT", with: "")
            let minutes = trimmed[minutesMatch].replacingOccurrences(of: "M", with: "")
            return "\(hours) u \(minutes) min"
        }

        if let hoursMatch = trimmed.range(of: #"(\d+)H"#, options: .regularExpression) {
            let hours = trimmed[hoursMatch].replacingOccurrences(of: "H", with: "").replacingOccurrences(of: "PT", with: "")
            return "\(hours) u"
        }

        if let minutesMatch = trimmed.range(of: #"(\d+)M"#, options: .regularExpression) {
            let minutes = trimmed[minutesMatch].replacingOccurrences(of: "M", with: "").replacingOccurrences(of: "PT", with: "")
            return "\(minutes) min"
        }

        return sanitizedText(from: trimmed)
    }

    private static func sanitizedText(from htmlString: String) -> String {
        let normalizedHTML = htmlString
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "</li>", with: "\n")

        if let data = normalizedHTML.data(using: .utf8),
           let attributedString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
           ) {
            return normalizedWhitespace(in: attributedString.string)
        }

        let stripped = normalizedHTML.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return normalizedWhitespace(in: stripped)
    }

    private static func normalizedWhitespace(in text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

struct ManageMealsView: View {
    @EnvironmentObject private var foodModel: FoodDataModel

    @State private var searchText = ""
    @State private var newMeal = Meal()
    @State private var isDeletingMeal = false
    @State private var mealPendingDeletion: Meal?
    @State private var deleteErrorMessage: String?

    private var filteredMeals: [Meal] {
        foodModel.savedMeals
            .filter { meal in
                let name = meal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Maaltijd zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Opgeslagen maaltijden") {
                if filteredMeals.isEmpty {
                    ContentUnavailableView(
                        "Geen maaltijden gevonden",
                        systemImage: "fork.knife",
                        description: Text("Voeg een nieuwe maaltijd toe of pas je zoekterm aan.")
                    )
                } else {
                    ForEach(filteredMeals, id: \.self) { meal in
                        NavigationLink(destination: ManageSavedMealDetailView(meal: meal)) {
                            ManageSavedMealRow(meal: meal)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                mealPendingDeletion = meal
                            } label: {
                                Label("Verwijder", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Beheer maaltijden")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ManageSavedMealDetailView(meal: newMeal, isNewMeal: true)) {
                    Text("Nieuw")
                }
            }
        }
        .alert("Verwijder maaltijd?", isPresented: deleteConfirmationBinding, presenting: mealPendingDeletion) { meal in
            Button("Annuleer", role: .cancel) {
                mealPendingDeletion = nil
            }
            Button("Verwijder", role: .destructive) {
                delete(meal)
            }
        } message: { meal in
            Text("'\(meal.name?.isEmpty == false ? meal.name! : "Deze maaltijd")' wordt verwijderd uit je opgeslagen maaltijden.")
        }
        .alert("Verwijderen mislukt", isPresented: deleteErrorBinding) {
            Button("Ok", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "Er ging iets mis.")
        }
        .onAppear {
            foodModel.getMeals()
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { mealPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    mealPendingDeletion = nil
                }
            }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    deleteErrorMessage = nil
                }
            }
        )
    }

    private func delete(_ meal: Meal) {
        guard !isDeletingMeal else {
            return
        }

        isDeletingMeal = true
        foodModel.deleteSavedMeal(meal) { result in
            isDeletingMeal = false
            mealPendingDeletion = nil

            if case .failure(let error) = result {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }
}

private struct ManageSavedMealRow: View {
    let meal: Meal

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let imageURLString = meal.recipe?.imageStorageURL ?? meal.recipe?.imageSourceURL,
               let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(meal.name?.isEmpty == false ? meal.name! : "Naamloze maaltijd")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let totalTimeText = meal.recipe?.totalTimeText, !totalTimeText.isEmpty {
                    Label(totalTimeText, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 12) {
                    ManageMealMacroValue(title: "Kcal", value: NumberHelper.roundedNumbersFromDouble(unit: meal.kcal))
                    ManageMealMacroValue(title: "Koolh", value: NumberHelper.roundedNumbersFromDouble(unit: meal.carbs))
                    ManageMealMacroValue(title: "Eiwit", value: NumberHelper.roundedNumbersFromDouble(unit: meal.protein))
                    ManageMealMacroValue(title: "Vet", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fat))
                    ManageMealMacroValue(title: "Vezel", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fiber))
                }
            }
        }
        .padding(.vertical, 4)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

private struct ManageMealMacroValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ManageSavedMealDetailView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    var isNewMeal = false

    @State private var editableMeal: Meal
    @State private var showAddProduct = false
    @State private var showRecipeBrowser = false
    @State private var parsedRecipePreview: ParsedRecipe?
    @State private var isParsingRecipe = false
    @State private var isImportingRecipe = false
    @State private var isSavingMeal = false
    @State private var isDeletingMeal = false
    @State private var pendingImportedIngredients = [PendingImportedIngredient]()
    @State private var resolvedImportedIngredientTexts = Set<String>()
    @State private var ignoredImportedIngredientTexts = Set<String>()
    @State private var importErrorMessage: String?
    @State private var showDeleteConfirmation = false

    init(meal: Meal, isNewMeal: Bool = false) {
        self.meal = meal
        self.isNewMeal = isNewMeal
        _editableMeal = State(initialValue: meal)
    }

    private var displayedMealName: String {
        let trimmedName = editableMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Maaltijd" : trimmedName
    }

    private var recipePreviewBinding: Binding<Bool> {
        Binding(
            get: { parsedRecipePreview != nil },
            set: { isPresented in
                if !isPresented {
                    parsedRecipePreview = nil
                }
            }
        )
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        List {
            if let recipe = editableMeal.recipe {
                Section {
                    MealRecipeHero(recipe: recipe)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            Section("Titel") {
                TextField("Maaltijdnaam", text: Binding(
                    get: { editableMeal.name ?? "" },
                    set: { editableMeal.name = $0 }
                ))
            }

            Section("Ingredienten") {
                if let products = editableMeal.products, !products.isEmpty {
                    ForEach(products, id: \.id) { product in
                        NavigationLink {
                            ManageMealEditProductView(product: product) { updatedProduct in
                                updateProduct(updatedProduct)
                            }
                        } label: {
                            ManageMealLocalProductRow(product: product)
                        }
                    }
                    .onDelete(perform: deleteProduct)
                } else {
                    ContentUnavailableView(
                        "Nog geen ingredienten",
                        systemImage: "fork.knife",
                        description: Text("Voeg producten toe om deze maaltijd op te slaan.")
                    )
                }

                Button {
                    showAddProduct = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Voeg product toe")
                    }
                    .foregroundColor(.accentColor)
                }
            }

            if (editableMeal.documentID?.isEmpty != false) && !pendingImportedIngredients.isEmpty {
                Section("Koppel ingrediënten") {
                    ForEach(pendingImportedIngredients) { ingredient in
                        NavigationLink {
                            ManageImportedIngredientMatchView(ingredient: ingredient) { product in
                                resolveImportedIngredient(ingredient, with: product)
                            }
                        } label: {
                            PendingImportedIngredientRow(ingredient: ingredient)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                ignoreImportedIngredient(ingredient)
                            } label: {
                                Label("Negeer", systemImage: "xmark")
                            }
                        }
                    }
                }
            }

            Section("Totaal") {
                MealMacroSummaryRow(title: "Calorieën", value: NumberHelper.roundedNumbersFromDouble(unit: editableMeal.kcal))
                MealMacroSummaryRow(title: "Koolhydraten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: editableMeal.carbs))
                MealMacroSummaryRow(title: "Eiwitten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: editableMeal.protein))
                MealMacroSummaryRow(title: "Vetten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: editableMeal.fat))
                MealMacroSummaryRow(title: "Vezels", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: editableMeal.fiber))
            }

            Section("Bereiding") {
                if let recipe = editableMeal.recipe {
                    MealRecipeCard(recipe: recipe)
                } else {
                    ContentUnavailableView(
                        "Nog geen recept",
                        systemImage: "book.closed",
                        description: Text("Importeer een receptpagina met Recipe structured data.")
                    )
                }

                Button {
                    showRecipeBrowser = true
                } label: {
                    HStack {
                        Image(systemName: "safari")
                        Text("Importeer recept")
                    }
                }

                if isParsingRecipe || isImportingRecipe {
                    HStack {
                        ProgressView()
                        Text(isImportingRecipe ? "Recept opslaan..." : "Recept analyseren...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(displayedMealName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddProduct) {
            NavigationStack {
                ManageMealAddProductView { product in
                    appendProduct(product)
                }
            }
        }
        .sheet(isPresented: $showRecipeBrowser) {
            RecipeBrowserSheet { confirmedURL in
                showRecipeBrowser = false
                Task {
                    await loadRecipePreview(from: confirmedURL)
                }
            }
        }
        .sheet(isPresented: recipePreviewBinding) {
            if let parsedRecipePreview {
                RecipeImportPreviewSheet(
                    recipe: parsedRecipePreview,
                    isImporting: isImportingRecipe,
                    onImport: {
                        Task {
                            await importRecipe(parsedRecipePreview)
                        }
                    }
                )
            }
        }
        .alert("Recept importeren mislukt", isPresented: importErrorBinding) {
            Button("Ok", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? "Er ging iets mis.")
        }
        .toolbar {
            if !isNewMeal {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(isDeletingMeal || editableMeal.documentID?.isEmpty != false || isSavingMeal)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isSavingMeal ? "Opslaan..." : "Opslaan") {
                    saveMeal()
                }
                .disabled(isSavingMeal || displayedMealName == "Maaltijd")
            }
        }
        .alert("Verwijder maaltijd?", isPresented: $showDeleteConfirmation) {
            Button("Annuleer", role: .cancel) {}
            Button("Verwijder", role: .destructive) {
                deleteMeal()
            }
        } message: {
            Text("Deze opgeslagen maaltijd wordt verwijderd.")
        }
        .onAppear {
            if foodModel.slimProductList.products.isEmpty {
                foodModel.fetchSlimProductList()
            }
            recalculateTotals()
            rebuildPendingImportedIngredients()
        }
    }

    private func appendProduct(_ product: Product) {
        if editableMeal.products == nil {
            editableMeal.products = [product]
        } else {
            editableMeal.products?.append(product)
        }
        recalculateTotals()
    }

    private func updateProduct(_ product: Product) {
        guard let index = editableMeal.products?.firstIndex(where: { $0.id == product.id }) else {
            return
        }
        editableMeal.products?[index] = product
        recalculateTotals()
    }

    private func deleteProduct(at offsets: IndexSet) {
        editableMeal.products?.remove(atOffsets: offsets)
        recalculateTotals()
        rebuildPendingImportedIngredients()
    }

    private func recalculateTotals() {
        editableMeal.kcal = editableMeal.products?.reduce(0) { $0 + ($1.selectedProductDetails?.kcal ?? 0) } ?? 0
        editableMeal.carbs = editableMeal.products?.reduce(0) { $0 + ($1.selectedProductDetails?.carbs ?? 0) } ?? 0
        editableMeal.protein = editableMeal.products?.reduce(0) { $0 + ($1.selectedProductDetails?.protein ?? 0) } ?? 0
        editableMeal.fat = editableMeal.products?.reduce(0) { $0 + ($1.selectedProductDetails?.fat ?? 0) } ?? 0
        editableMeal.fiber = editableMeal.products?.reduce(0) { $0 + ($1.selectedProductDetails?.fiber ?? 0) } ?? 0
    }

    private func saveMeal() {
        isSavingMeal = true
        foodModel.saveMeal(for: editableMeal) { result in
            isSavingMeal = false

            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
    }

    private func deleteMeal() {
        guard !isDeletingMeal else {
            return
        }

        isDeletingMeal = true
        foodModel.deleteSavedMeal(editableMeal) { result in
            isDeletingMeal = false

            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func loadRecipePreview(from url: URL) async {
        isParsingRecipe = true
        defer { isParsingRecipe = false }

        do {
            parsedRecipePreview = try await RecipeStructuredDataImporter.parseRecipe(from: url)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func importRecipe(_ recipe: ParsedRecipe) async {
        isImportingRecipe = true
        defer { isImportingRecipe = false }

        do {
            editableMeal.recipe = try await foodModel.importedMealRecipe(from: recipe)
            if (editableMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                editableMeal.name = recipe.title
            }
            await applyImportedIngredients(from: recipe)
            parsedRecipePreview = nil
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func applyImportedIngredients(from recipe: ParsedRecipe) async {
        var unresolved = [PendingImportedIngredient]()
        var resolvedTexts = Set<String>()

        for ingredient in recipe.ingredients {
            let parsedAmount = ImportedIngredientAmountParser.amount(from: ingredient)
            let suggestedProduct = suggestedSlimProduct(for: ingredient)

            if let suggestedProduct,
               let parsedAmount,
               let matchedProduct = await fetchedProduct(documentID: suggestedProduct.documentID) {
                var resolvedProduct = matchedProduct
                resolvedProduct.selectedProductDetails = SelectedProductDetails(
                    kcal: calculate(unit: matchedProduct.kcal, portion: parsedAmount),
                    carbs: calculate(unit: matchedProduct.carbs, portion: parsedAmount),
                    protein: calculate(unit: matchedProduct.protein, portion: parsedAmount),
                    fat: calculate(unit: matchedProduct.fat, portion: parsedAmount),
                    fiber: calculate(unit: matchedProduct.fiber, portion: parsedAmount),
                    amount: parsedAmount
                )
                appendProductIfNeeded(resolvedProduct)
                resolvedTexts.insert(ingredient)
            } else {
                unresolved.append(
                    PendingImportedIngredient(
                        originalText: ingredient,
                        suggestedProduct: suggestedProduct,
                        suggestedAmount: parsedAmount
                    )
                )
            }
        }

        resolvedImportedIngredientTexts = resolvedTexts
        pendingImportedIngredients = unresolved
    }

    private func resolveImportedIngredient(_ ingredient: PendingImportedIngredient, with product: Product) {
        appendProductIfNeeded(product)
        resolvedImportedIngredientTexts.insert(ingredient.originalText)
        pendingImportedIngredients.removeAll { $0.id == ingredient.id }
    }

    private func ignoreImportedIngredient(_ ingredient: PendingImportedIngredient) {
        ignoredImportedIngredientTexts.insert(ingredient.originalText)
        pendingImportedIngredients.removeAll { $0.id == ingredient.id }
    }

    private func rebuildPendingImportedIngredients() {
        guard let recipe = editableMeal.recipe else {
            pendingImportedIngredients = []
            return
        }

        let existingProductNames = Set((editableMeal.products ?? []).map { normalizedMatchingText($0.name) })
        pendingImportedIngredients = (recipe.ingredients ?? []).compactMap { ingredient in
            if resolvedImportedIngredientTexts.contains(ingredient) {
                return nil
            }

            if ignoredImportedIngredientTexts.contains(ingredient) {
                return nil
            }

            let suggestedProduct = suggestedSlimProduct(for: ingredient)
            if let suggestedProduct, existingProductNames.contains(normalizedMatchingText(suggestedProduct.name)) {
                return nil
            }

            return PendingImportedIngredient(
                originalText: ingredient,
                suggestedProduct: suggestedProduct,
                suggestedAmount: ImportedIngredientAmountParser.amount(from: ingredient)
            )
        }
    }

    private func appendProductIfNeeded(_ product: Product) {
        if let index = editableMeal.products?.firstIndex(where: { normalizedMatchingText($0.name) == normalizedMatchingText(product.name) }) {
            editableMeal.products?[index] = product
        } else if editableMeal.products == nil {
            editableMeal.products = [product]
        } else {
            editableMeal.products?.append(product)
        }

        recalculateTotals()
    }

    private func suggestedSlimProduct(for ingredient: String) -> SlimProduct? {
        let normalizedIngredient = normalizedMatchingText(ingredient)
        guard !normalizedIngredient.isEmpty else {
            return nil
        }

        let candidates = foodModel.slimProductList.products
            .map { product in
                (product, IngredientProductMatcher.score(ingredient: normalizedIngredient, productName: normalizedMatchingText(product.name)))
            }
            .filter { $0.1 > 0.45 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.name < rhs.0.name
                }
                return lhs.1 > rhs.1
            }

        return candidates.first?.0
    }

    private func normalizedMatchingText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func calculate(unit: Double, portion: Int) -> Double {
        let per1gram = unit / 100
        return (per1gram * Double(portion)).rounded()
    }

    private func fetchedProduct(documentID: String) async -> Product? {
        await withCheckedContinuation { continuation in
            foodModel.getProductDetails(documentID: documentID) { product, _ in
                continuation.resume(returning: product)
            }
        }
    }
}

private struct ManageMealLocalProductRow: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .foregroundStyle(.primary)
                Text("\(product.selectedProductDetails?.amount ?? 0) gram")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(NumberHelper.roundedNumbersFromDouble(unit: product.selectedProductDetails?.kcal ?? 0))
                .foregroundStyle(.secondary)
        }
    }
}

private struct PendingImportedIngredient: Identifiable, Hashable {
    let id = UUID()
    let originalText: String
    let suggestedProduct: SlimProduct?
    let suggestedAmount: Int?
}

private struct PendingImportedIngredientRow: View {
    let ingredient: PendingImportedIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ingredient.originalText)
                .foregroundStyle(.primary)

            if let suggestedProduct = ingredient.suggestedProduct {
                Text("Suggestie: \(suggestedProduct.name)\(ingredient.suggestedAmount.map { " • \($0) g/ml" } ?? "")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Nog geen match gevonden")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private enum IngredientProductMatcher {
    static func score(ingredient: String, productName: String) -> Double {
        let ingredientTokens = Set(ingredient.split(separator: " ").map(String.init).filter { $0.count > 1 })
        let productTokens = Set(productName.split(separator: " ").map(String.init).filter { $0.count > 1 })

        guard !ingredientTokens.isEmpty, !productTokens.isEmpty else {
            return 0
        }

        let overlap = ingredientTokens.intersection(productTokens).count
        let baseScore = Double(overlap) / Double(productTokens.count)

        if ingredient.contains(productName) || productName.contains(ingredient) {
            return max(baseScore, 0.95)
        }

        return baseScore
    }
}

private enum ImportedIngredientAmountParser {
    static func amount(from text: String) -> Int? {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: ",", with: ".")

        guard let value = firstNumericValue(in: normalized) else {
            return nil
        }

        if normalized.contains("kg") {
            return Int(value * 1000)
        }

        if normalized.contains("gram") || normalized.contains(" gr") || normalized.contains(" g ") || normalized.hasSuffix(" g") {
            return Int(value)
        }

        if normalized.contains("liter") || normalized.contains(" l ") || normalized.hasSuffix(" l") {
            return Int(value * 1000)
        }

        if normalized.contains("ml") || normalized.contains("milliliter") {
            return Int(value)
        }

        return nil
    }

    private static func firstNumericValue(in text: String) -> Double? {
        let pattern = #"\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        return Double(text[range])
    }
}

private struct ManageImportedIngredientMatchView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    let ingredient: PendingImportedIngredient
    let onResolve: (Product) -> Void

    @State private var searchText = ""
    @State private var didResolve = false
    @State private var showAddProduct = false

    private var filteredProducts: [SlimProduct] {
        foodModel.slimProductList.products
            .filter { product in
                searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section("Ingrediënt") {
                Text(ingredient.originalText)
            }

            Section {
                PickerSearchBar(text: $searchText, placeholder: "Product zoeken")
                    .listRowInsets(EdgeInsets())
            }

            if let suggestedProduct = ingredient.suggestedProduct {
                Section("Suggestie") {
                    NavigationLink {
                        ManageMealNewProductDetailView(
                            documentID: suggestedProduct.documentID,
                            initialAmount: ingredient.suggestedAmount ?? 100
                        ) { product in
                            onResolve(product)
                            didResolve = true
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestedProduct.name)
                            Text("Voorgestelde hoeveelheid: \(ingredient.suggestedAmount ?? 100) g/ml")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Beschikbare producten") {
                ForEach(filteredProducts, id: \.self) { product in
                    NavigationLink {
                        ManageMealNewProductDetailView(
                            documentID: product.documentID,
                            initialAmount: ingredient.suggestedAmount ?? 100
                        ) { resolvedProduct in
                            onResolve(resolvedProduct)
                            didResolve = true
                        }
                    } label: {
                        Text(product.name)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Koppel ingrediënt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddProduct) {
            AddProductView(showAddProduct: $showAddProduct)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddProduct = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: didResolve) { _, resolved in
            if resolved {
                dismiss()
            }
        }
    }
}

private struct ManageMealAddProductView: View {
    @EnvironmentObject private var foodModel: FoodDataModel

    let onSaveProduct: (Product) -> Void

    @State private var searchText = ""
    @State private var showAddProduct = false

    private var filteredProducts: [SlimProduct] {
        foodModel.slimProductList.products
            .filter { product in
                searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Product zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Beschikbare producten") {
                if filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "Geen producten gevonden",
                        systemImage: "magnifyingglass",
                        description: Text("Pas je zoekterm aan of voeg een nieuw product toe.")
                    )
                } else {
                    ForEach(filteredProducts, id: \.self) { product in
                        NavigationLink {
                            ManageMealNewProductDetailView(documentID: product.documentID, initialAmount: 100, onSaveProduct: onSaveProduct)
                        } label: {
                            Text(product.name)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Product kiezen")
        .sheet(isPresented: $showAddProduct) {
            AddProductView(showAddProduct: $showAddProduct)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Nieuw") {
                    showAddProduct = true
                }
            }
        }
        .onAppear {
            if foodModel.slimProductList.products.isEmpty {
                foodModel.fetchSlimProductList()
            }
        }
    }
}

private struct ManageMealNewProductDetailView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    let documentID: String
    let initialAmount: Int
    let onSaveProduct: (Product) -> Void

    @State private var product: Product?
    @State private var loadError = false

    var body: some View {
        Group {
            if let product {
                ProductIntakeEditorView(
                    product: product,
                    initialAmount: initialAmount,
                    saveButtonTitle: "Sla op",
                    onSave: { createdProduct in
                        var updatedProduct = product
                        updatedProduct.selectedProductDetails = createdProduct
                        onSaveProduct(updatedProduct)
                        return true
                    },
                    onSuccess: {
                        dismiss()
                    }
                )
            } else if loadError {
                ContentUnavailableView(
                    "Product laden mislukt",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Probeer het opnieuw vanuit de lijst.")
                )
            } else {
                ProgressView()
                    .navigationTitle("Product laden")
            }
        }
        .onAppear {
            guard product == nil else {
                return
            }
            foodModel.getProductDetails(documentID: documentID) { loadedProduct, error in
                if let loadedProduct, error.isEmpty {
                    product = loadedProduct
                } else {
                    loadError = true
                }
            }
        }
    }
}

private struct ManageMealEditProductView: View {
    @Environment(\.dismiss) private var dismiss

    let product: Product
    let onSaveProduct: (Product) -> Void

    var body: some View {
        ProductIntakeEditorView(
            product: product,
            initialAmount: product.selectedProductDetails?.amount ?? 100,
            saveButtonTitle: "Sla op",
            onSave: { createdProduct in
                var updatedProduct = product
                updatedProduct.selectedProductDetails = createdProduct
                onSaveProduct(updatedProduct)
                return true
            },
            onSuccess: {
                dismiss()
            }
        )
    }
}

#Preview {
    FoodPreviewContainer(
        diary: FoodDiary(
            meals: [
                Meal(
                    name: "Lunch",
                    products: [
                        Product(
                            name: "Havermout",
                            kcal: 380,
                            carbs: 62,
                            protein: 13,
                            fat: 7,
                            fiber: 9,
                            selectedProductDetails: SelectedProductDetails(kcal: 304, carbs: 49.6, protein: 10.4, fat: 5.6, fiber: 7.2, amount: 80)
                        )
                    ],
                    kcal: 304,
                    carbs: 49.6,
                    protein: 10.4,
                    fat: 5.6,
                    fiber: 7.2
                )
            ]
        )
    ) {
        NavigationStack {
            MealDetailView(meal: Meal(name: "Lunch"))
        }
    }
}
