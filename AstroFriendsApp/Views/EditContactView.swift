import SwiftUI
import SwiftData
import CoreLocation
import MapKit

// MARK: - Location Search Completer
class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        isSearching = false
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        searchResults = []
        isSearching = false
    }
}

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var contact: Contact
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var zodiacSign: ZodiacSign = .aries
    @State private var isFavorite: Bool = false
    @State private var birthday: Date? = nil
    @State private var birthTime: Date? = nil
    @State private var birthPlace: String = ""
    @State private var coordinates: CLLocationCoordinate2D? = nil
    @State private var showingLocationSearch: Bool = false
    
    @StateObject private var locationCompleter = LocationSearchCompleter()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Birth Data") {
                    // Birthday - optional date picker
                    HStack {
                        Text("Birthday")
                        Spacer()
                        if let bday = birthday {
                            DatePicker("", selection: Binding(
                                get: { bday },
                                set: { newDate in
                                    birthday = newDate
                                    zodiacSign = ZodiacSign.from(birthday: newDate)
                                }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            
                            Button {
                                birthday = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button("Add") {
                                birthday = Date()
                                zodiacSign = ZodiacSign.from(birthday: Date())
                            }
                            .foregroundColor(.indigo)
                        }
                    }
                    
                    // Birth Time - optional time picker
                    HStack {
                        Text("Birth Time")
                        Spacer()
                        if let time = birthTime {
                            DatePicker("", selection: Binding(
                                get: { time },
                                set: { birthTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            
                            Button {
                                birthTime = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button("Add") {
                                // Default to noon
                                let calendar = Calendar.current
                                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                                components.hour = 12
                                components.minute = 0
                                birthTime = calendar.date(from: components)
                            }
                            .foregroundColor(.indigo)
                        }
                    }
                    
                    // Birth Place with Apple Maps search
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showingLocationSearch = true
                        } label: {
                            HStack {
                                Text("Birth City")
                                    .foregroundColor(.primary)
                                Spacer()
                                if birthPlace.isEmpty {
                                    Text("Search...")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(birthPlace)
                                        .foregroundColor(.indigo)
                                        .lineLimit(1)
                                }
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if let coords = coordinates {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.indigo)
                                    .font(.caption)
                                Text(formatCoordinates(coords))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if !birthPlace.isEmpty {
                                    Button {
                                        birthPlace = ""
                                        coordinates = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                Section("Zodiac Sign") {
                    Picker("Sign", selection: $zodiacSign) {
                        ForEach(ZodiacSign.allCases, id: \.self) { sign in
                            HStack {
                                Text(sign.emoji)
                                Text(sign.rawValue)
                            }
                            .tag(sign)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    HStack {
                        Text("Element")
                        Spacer()
                        Text(zodiacSign.element)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date Range")
                        Spacer()
                        Text(zodiacSign.dateRange)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadContactData()
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(
                    selectedPlace: $birthPlace,
                    coordinates: $coordinates,
                    completer: locationCompleter
                )
            }
        }
    }
    
    private func loadContactData() {
        name = contact.name
        phoneNumber = contact.phoneNumber ?? ""
        email = contact.email ?? ""
        notes = contact.notes
        zodiacSign = contact.zodiacSign
        isFavorite = contact.isFavorite
        birthday = contact.birthday
        birthTime = contact.birthTime
        birthPlace = contact.birthPlace ?? ""
        
        // Geocode existing birth place if we have one
        if !birthPlace.isEmpty {
            geocodeExistingPlace(birthPlace)
        }
    }
    
    private func saveChanges() {
        contact.name = name
        contact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        contact.email = email.isEmpty ? nil : email
        contact.notes = notes
        contact.zodiacSign = zodiacSign
        contact.isFavorite = isFavorite
        contact.birthday = birthday
        contact.birthTime = birthTime
        contact.birthPlace = birthPlace.isEmpty ? nil : birthPlace
    }
    
    private func geocodeExistingPlace(_ place: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place) { placemarks, error in
            if let location = placemarks?.first?.location {
                self.coordinates = location.coordinate
            }
        }
    }
    
    private func formatCoordinates(_ coord: CLLocationCoordinate2D) -> String {
        let latDirection = coord.latitude >= 0 ? "N" : "S"
        let lonDirection = coord.longitude >= 0 ? "E" : "W"
        return String(format: "%.4f° %@, %.4f° %@", 
                      abs(coord.latitude), latDirection,
                      abs(coord.longitude), lonDirection)
    }
}

// MARK: - Location Search View
struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlace: String
    @Binding var coordinates: CLLocationCoordinate2D?
    @ObservedObject var completer: LocationSearchCompleter
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search city or place...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            completer.search(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            completer.search(query: "")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Results list
                if completer.isSearching {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                } else if completer.searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(completer.searchResults, id: \.self) { result in
                        Button {
                            selectLocation(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let mapItem = response?.mapItems.first {
                let placeName = [completion.title, completion.subtitle]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                
                selectedPlace = placeName
                coordinates = mapItem.placemark.coordinate
                dismiss()
            }
        }
    }
}
