import SwiftUI

enum AnalysisCategory: String, CaseIterable, Identifiable, Sendable {
    case manglendeCRP = "Manglende CRP ved luftvejsinfektion"
    case manglendeUVI = "Manglende UVI-prøvepakke"
    case manglendeSamtaleterapi = "Manglende samtaleterapi-koder"
    case manglendeBesoeg = "Manglende besøgsydelse"
    case forkertGrundydelse = "Forkerte grundydelser"
    case sygeplejerOpkald = "Sygeplejerske-opkald uden ydelse"
    case notaterUdenYdelse = "Notater uden ydelse"
    case manglendeEKGLFU = "Planlagt EKG/LFU ikke udført"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .manglendeCRP: return "lungs"
        case .manglendeUVI: return "drop.triangle"
        case .manglendeSamtaleterapi: return "brain.head.profile"
        case .manglendeBesoeg: return "house"
        case .forkertGrundydelse: return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .sygeplejerOpkald: return "phone.badge.waveform"
        case .notaterUdenYdelse: return "doc.text"
        case .manglendeEKGLFU: return "waveform.path.ecg"
        }
    }

    var color: Color {
        switch self {
        case .manglendeCRP: return .red
        case .manglendeUVI: return .orange
        case .manglendeSamtaleterapi: return .purple
        case .manglendeBesoeg: return .blue
        case .forkertGrundydelse: return .pink
        case .sygeplejerOpkald: return .teal
        case .notaterUdenYdelse: return .indigo
        case .manglendeEKGLFU: return .mint
        }
    }

    var estimatedValuePerCase: Double {
        switch self {
        case .manglendeCRP: return 75.93          // 7120
        case .manglendeUVI: return 156.29         // 2101 + 2133 + 7122
        case .manglendeSamtaleterapi: return 454.66  // 4609/4610
        case .manglendeBesoeg: return 175.0       // besøgsydelse
        case .forkertGrundydelse: return 120.0    // gennemsnit diff
        case .sygeplejerOpkald: return 130.0      // 204
        case .notaterUdenYdelse: return 80.0      // blandet
        case .manglendeEKGLFU: return 150.0       // EKG/LFU tillægsydelse
        }
    }

    var overenskomstTekst: String {
        switch self {
        case .manglendeCRP:
            return "Ydelse 7120 (CRP, 75,93 kr) kan tages som tillægsydelse ved luftvejsinfektioner. PLO-overenskomsten §42."
        case .manglendeUVI:
            return "Ved UVI bør tages: 2101 (blodtagning, 55,72 kr), 2133 (forsendelse, 39,82 kr), 7122 (mikroskopi urin, 60,75 kr). PLO-overenskomsten §42."
        case .manglendeSamtaleterapi:
            return "Ydelse 4609 (krisesamtale, 454,66 kr) eller 4610 (samtaleterapi, 454,66 kr) kan afregnes ved samtaler med psykisk indhold. PLO-overenskomsten §72."
        case .manglendeBesoeg:
            return "Besøg skal afregnes med besøgsydelse (0111 sygebesøg eller lignende). PLO-overenskomsten §34."
        case .forkertGrundydelse:
            return "Videokonsultation = 0125 (163,18 kr), konsultation = 0101 (172,88 kr), e-konsultation = 0105 (51,12 kr). Forkert grundydelse giver tabt honorar. PLO-overenskomsten §30-33."
        case .sygeplejerOpkald:
            return "Når sygeplejerske ringer patient op bør det udløse 0124 (lægefaglig vurdering, 175,71 kr), 0201 (telefonkonsultation, 31,84 kr) eller 0204 (aftalt telefon, 130,10 kr). PLO-overenskomsten §31."
        case .notaterUdenYdelse:
            return "Klinisk arbejde dokumenteret i journal bør udløse relevant ydelse. Patient-initierede henvendelser (mails) kan IKKE udløse ydelse per overenskomsten."
        case .manglendeEKGLFU:
            return "Når årsprogram/dagsprogram angiver EKG eller LFU (lungefunktionsundersøgelse/spirometri), og den tilhørende tillægsydelse (7113 EKG, 7121 spirometri) ikke er afregnet, kan der mangle en ydelse."
        }
    }
}
