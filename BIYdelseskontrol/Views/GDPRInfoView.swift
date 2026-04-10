import SwiftUI

struct GDPRInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)

                    Text("GDPR & Datasikkerhed")
                        .font(.largeTitle.bold())

                    Text("Al databehandling sker lokalt på din computer")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                // Status badges
                HStack(spacing: 16) {
                    gdprBadge(icon: "network.slash", title: "Ingen internet", subtitle: "Data forlader aldrig din computer")
                    gdprBadge(icon: "icloud.slash", title: "Ingen cloud", subtitle: "Ingen data sendes til servere")
                    gdprBadge(icon: "externaldrive", title: "Kun lokalt", subtitle: "Alt gemmes på din maskine")
                    gdprBadge(icon: "trash", title: "Intet spor", subtitle: "Ingen data gemmes efter lukning")
                }

                Divider()

                // Detailed sections
                infoSection(
                    title: "Hvad appen gør",
                    items: [
                        "Indlæser dine Excel/CSV-filer fra din computer",
                        "Analyserer data lokalt med regelbaseret logik — ingen AI",
                        "Krydsrefererer bookinger med ydelser for at finde fejl",
                        "Genererer kontrolark som Excel-filer på din computer"
                    ]
                )

                infoSection(
                    title: "Hvad appen IKKE gør",
                    items: [
                        "Sender INGEN data over internettet",
                        "Bruger INGEN cloud-tjenester eller AI-services",
                        "Gemmer INGEN data permanent — alt forsvinder når appen lukkes",
                        "Indsamler INGEN telemetri, analytics eller brugerdata",
                        "Har INGEN netværksadgang overhovedet"
                    ]
                )

                infoSection(
                    title: "Juridisk grundlag",
                    items: [
                        "Ingen persondata forlader din computer → ingen databehandleraftale nødvendig",
                        "Data behandles udelukkende i den dataansvarliges eget miljø",
                        "Appen fungerer som et digitalt regneark — samme GDPR-status som Excel",
                        "CPR-numre og patientdata forbliver i det lokale filsystem",
                        "Overholder GDPR art. 25 (data protection by design)"
                    ]
                )

                infoSection(
                    title: "Teknisk sikkerhed",
                    items: [
                        "macOS App Sandbox forhindrer adgang til filer du ikke vælger",
                        "Appen kan kun læse filer du eksplicit vælger via fil-dialogen",
                        "Ingen baggrunds-processer efter appen lukkes",
                        "Ingen persistering af sundhedsdata mellem sessioner"
                    ]
                )

                // Footer
                VStack(spacing: 8) {
                    Divider()
                    Text("BI Ydelseskontrol behandler sundhedsdata (GDPR art. 9) udelukkende lokalt. Al analyse er regelbaseret og kræver ingen internet-forbindelse.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
            }
            .padding(32)
        }
    }

    private func gdprBadge(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(title)
                .font(.caption.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    private func infoSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(item)
                        .font(.body)
                }
            }
        }
    }
}

#Preview {
    GDPRInfoView()
}
