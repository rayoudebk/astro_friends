import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var contact: Contact
    
    @State private var showingEditSheet = false
    @State private var showingCheckInSheet = false
    @State private var showingHoroscope = false
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: contact.zodiacSign)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                contactHeaderCard
                
                // Zodiac & Horoscope Card
                zodiacCard
                
                // Contact Info
                if contact.phoneNumber != nil || contact.email != nil {
                    contactInfoSection
                }
                
                // Check-in History
                checkInHistorySection
                
                // Notes
                if !contact.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        contact.isFavorite.toggle()
                    } label: {
                        Label(contact.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                              systemImage: contact.isFavorite ? "star.slash" : "star")
                    }
                    
                    Button(role: .destructive) {
                        modelContext.delete(contact)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: contact)
        }
        .sheet(isPresented: $showingCheckInSheet) {
            CheckInSheetView(contact: contact)
        }
        .sheet(isPresented: $showingHoroscope) {
            HoroscopeDetailView(sign: contact.zodiacSign)
        }
    }
    
    private var contactHeaderCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                if let imageData = contact.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(elementColor(for: contact.zodiacSign).opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Text(contact.name.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(elementColor(for: contact.zodiacSign))
                }
            }
            
            // Name and status
            VStack(spacing: 8) {
                HStack {
                    Text(contact.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if contact.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Status
                if contact.isOverdue {
                    Label("Waiting for you", systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                } else if let lastCheckIn = contact.lastCheckInDate {
                    Text("Last check-in: \(lastCheckIn, style: .relative) ago")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No check-ins yet")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            
            // Check-in button
            Button {
                showingCheckInSheet = true
            } label: {
                Label("Record Check-in", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
    }
    
    private var zodiacCard: some View {
        Button {
            showingHoroscope = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(contact.zodiacSign.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.zodiacSign.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(contact.zodiacSign.dateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(horoscope.mood)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(elementColor(for: contact.zodiacSign).opacity(0.2))
                            .foregroundColor(elementColor(for: contact.zodiacSign))
                            .cornerRadius(8)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("This week: \(horoscope.weeklyReading)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Info")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let phone = contact.phoneNumber {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text(phone)
                        Spacer()
                        
                        Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                            Image(systemName: "phone.arrow.up.right")
                                .foregroundColor(.indigo)
                        }
                        
                        Link(destination: URL(string: "sms:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                }
                
                if let email = contact.email {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text(email)
                        Spacer()
                        
                        Link(destination: URL(string: "mailto:\(email)")!) {
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.indigo)
                        }
                    }
                }
                
                if let birthday = contact.birthday {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        Text(birthday, style: .date)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private var checkInHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Check-in History")
                    .font(.headline)
                Spacer()
                Text("Every \(contact.frequencyDays) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let checkIns = contact.checkIns, !checkIns.isEmpty {
                VStack(spacing: 0) {
                    ForEach(checkIns.sorted(by: { $0.date > $1.date }).prefix(5)) { checkIn in
                        HStack {
                            Image(systemName: checkIn.type.icon)
                                .foregroundColor(.indigo)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(checkIn.type.rawValue)
                                    .font(.subheadline)
                                
                                Text(checkIn.date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !checkIn.notes.isEmpty {
                                Image(systemName: "note.text")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if checkIn.id != checkIns.sorted(by: { $0.date > $1.date }).prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No check-ins yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            Text(contact.notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
        }
    }
    
    private func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .red
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .blue
        default: return .gray
        }
    }
}

