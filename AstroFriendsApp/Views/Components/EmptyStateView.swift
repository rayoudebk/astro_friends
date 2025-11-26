import SwiftUI

struct EmptyStateView: View {
    let hasContacts: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if hasContacts {
                // Has contacts but filtered to empty
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("No matching contacts")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                // No contacts at all
                VStack(spacing: 16) {
                    Text("✨")
                        .font(.system(size: 60))
                    
                    Text("Welcome to Astro Friends!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Add your friends and discover their zodiac signs.\nTap the + button to get started.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}


