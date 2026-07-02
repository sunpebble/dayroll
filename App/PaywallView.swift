import SwiftUI

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("DAYROLL PRO")
                .font(Tape.font(20, weight: .bold))
                .kerning(4)
                .padding(.top, 32)
            Perforation()

            VStack(alignment: .leading, spacing: 14) {
                feature("square.and.arrow.up", "Export your whole tape")
                feature("chart.bar", "Mood stats & yearly review")
                feature("heart", "Support an indie developer")
            }
            .padding(.vertical, 8)

            Perforation()

            Text("PAY ONCE. YOURS FOREVER.\nNO SUBSCRIPTION. NO ACCOUNT.")
                .font(Tape.font(11, weight: .semibold))
                .foregroundStyle(Tape.faded)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await pro.purchase()
                    if pro.isPro { dismiss() }
                }
            } label: {
                Text("UNLOCK FOR \(pro.displayPrice)")
                    .font(Tape.font(15, weight: .bold))
                    .foregroundStyle(Tape.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Tape.ink))
            }

            if let error = pro.purchaseError {
                Text(error)
                    .font(Tape.font(11))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Restore Purchase") {
                Task {
                    await pro.restore()
                    if pro.isPro { dismiss() }
                }
            }
            .font(Tape.font(12))
            .foregroundStyle(Tape.faded)

            Spacer()
        }
        .padding(24)
        .background(Tape.paper)
        .tint(Tape.ink)
        .presentationDetents([.medium, .large])
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 24)
            Text(text).font(Tape.font(14))
        }
        .foregroundStyle(Tape.ink)
    }
}
