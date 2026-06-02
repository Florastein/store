# Store
Store is a premium, light-minimalist Flutter application designed for modern store management and customer engagement. The application prioritizes visual excellence and responsive interaction, featuring a highly-curated design language.

## Architecture & Core Philosophy

The project is structured around key design and component boundaries, emphasizing custom-tailored visual styling instead of generic templates:

*   **Design Aesthetics & Palette**: Implements a refined, warm-light minimalist system. Features custom HSL-tailored colors including Warm Off-White backgrounds, Charcoal primaries, deep black inputs, and highly calibrated semantic states (Forest Green, Warm Amber, Terracotta Rust).
*   **Custom Design Tokens (`lib/theme/app_colors.dart`)**: Houses the application's unified palette, maintaining absolute visual consistency across light and dark-mode adaptation.
*   **Custom-Engineered Core Widgets (`lib/widgets/`)**: Replaces standard Material design components with custom alternatives:
    *   `MyButton`: A fluid, responsive tap-feedback button matching the app's visual language.
    *   `AccountCard`: A dynamic, drop-shadowed card representing account options with deep-depth styling.
*   **Segmented Visual Journeys (`lib/pages/`)**: Separates flow states into isolated modules:
    *   `splash/`: Smooth, multi-phase animations guiding from a logo entry to loading progress indication.
    *   `onboarding/`: An animated carousel featuring swipeable pages and fluid page indicators.

---

## Directory Structure

```
lib/
├── main.dart             # Application initialization and routing root
├── theme/
│   └── app_colors.dart   # Unified color token system
├── widgets/
│   ├── acctount_cards.dart # Specialized AccountCard components
│   └── mybutton.dart     # Custom minimalist Gesture-based button
└── pages/
    ├── splash/
    │   ├── splash_one.dart # Animated fade-in logo page
    │   └── splash_two.dart # Linear loading & percentage tracking page
    └── onboarding/
        ├── onboard_one.dart # Animated onboarding slider and indicators
        └── account_type.dart # Role configuration (Customer / Store Owner)
```

---

## Technical Stack

*   **Framework**: Flutter (Dart SDK >= 3.11.5)
*   **Typography**: Google Fonts (Poppins) for premium visual hierarchy
*   **Icons**: Cupertino Icons & Material Icons

---

## Getting Started

### Prerequisites

*   Flutter SDK installed on your system.
*   An active virtual device (Android Emulator / iOS Simulator) or connected physical hardware.

### Development Execution

To download dependencies and launch the application in debug mode:

```bash
# Fetch required packages
flutter pub get

# Run the project locally on your active device
flutter run
```

### Static Analysis & Testing

Ensure that files adhere to our custom linting rules and run the widget test suite:

```bash
# Run dart analysis
flutter analyze

# Execute automated tests
flutter test
```
