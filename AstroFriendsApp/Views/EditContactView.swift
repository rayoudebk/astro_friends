import SwiftUI
import SwiftData
import CoreLocation

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
    @State private var isGeocodingError: Bool = false
    
    private let geocoder = CLGeocoder()
    
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
                    
                    // Birth Place
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Birth City", text: $birthPlace)
                            .onChange(of: birthPlace) { _, newValue in
                                if !newValue.isEmpty {
                                    geocodeCity(newValue)
                                } else {
                                    coordinates = nil
                                    isGeocodingError = false
                                }
                            }
                        
                        if let coords = coordinates {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.indigo)
                                    .font(.caption)
                                Text(formatCoordinates(coords))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if isGeocodingError && !birthPlace.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Location not found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
        
        // Geocode existing birth place
        if !birthPlace.isEmpty {
            geocodeCity(birthPlace)
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
    
    private func geocodeCity(_ city: String) {
        // Debounce - only geocode after user stops typing
        let searchCity = city
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only proceed if the city hasn't changed
            guard self.birthPlace == searchCity else { return }
            
            geocoder.cancelGeocode()
            geocoder.geocodeAddressString(city) { placemarks, error in
                if let location = placemarks?.first?.location {
                    self.coordinates = location.coordinate
                    self.isGeocodingError = false
                } else {
                    self.coordinates = nil
                    self.isGeocodingError = true
                }
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
