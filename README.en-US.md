

<img src="CSUSTPlanet/Resources/Assets.xcassets/MinimalLogo.imageset/logo_minimal.png" alt="长理星球" height="64">

# CSUSTPlanet

CSUSTPlanet is a campus service assistant designed for college students, making your campus life more convenient and efficient. Through this app, you can check your class schedule, exam scores, and exam arrangements anytime, monitor your dormitory power usage in real-time and receive low-power alerts, and quickly view course assignments and deadlines.

The campus network library for CSUSTPlanet is powered by [CSUSTKit](https://github.com/zHElEARN/CSUSTKit).

Supports iOS and iPadOS 17.0+, and macOS 14.0+.

## Installation

- Download and install via the [App Store](https://apps.apple.com/cn/app/%E9%95%BF%E7%90%86%E6%98%9F%E7%90%83/id6748840801)
- Join the test via [TestFlight](https://testflight.apple.com/join/xMbzN8aU)

## Building

> [!IMPORTANT]
> **Build Requirements**: Since CSUSTPlanet integrates specific **App Capabilities**, building this project requires membership in the **Apple Developer Program**. Using a free developer account may result in signing failures or compilation errors.

### Steps

1. Clone the repository

   ```bash
   git clone https://github.com/zHElEARN/CSUSTPlanet.git
   cd CSUSTPlanet
   ```

2. Project Configuration

   CSUSTPlanet uses `.xcconfig` files and environment variables to manage build configurations and sensitive information. Before building, you need to set up the following two configuration files:
   - Build Configuration (User.xcconfig)

     Copy the build configuration template file and fill in your developer team information:

     ```bash
     cp Configs/User.xcconfig.template Configs/User.xcconfig
     ```

   - Environment Variables (.env)

     Copy the environment variable template for Fastlane's signing management, and fill in the corresponding Apple ID and key information in the `.env` file:

     ```bash
     cp .env.template .env
     ```

3. Install Dependencies

   This project uses Bundler to manage Ruby dependencies (including Fastlane).

   ```bash
   gem install bundler
   ```

   Install the required Ruby gems and iOS dependency libraries:

   ```bash
   bundle install
   bundle exec fastlane ios sync_certs
   bundle exec fastlane mac sync_certs
   ```

   Install LicensePlist for generating the open-source license list:

   ```base
   brew install licenseplist
   ```

4. Run the Project

   Open the project file `CSUSTPlanet.xcodeproj` using Xcode to build and run the project.

## License

This project is licensed under the **MIT License**.

This means:

- You are free to commercially use, copy, modify, and distribute the source code and its copies of this project.
- You only need to retain the original author's copyright notice and license statement when distributing.
- You can integrate the project's code into your proprietary or commercial projects without the need to disclose your own source code.
- The author assumes no legal responsibility for any consequences arising from the use of this project.

See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions to **CSUSTPlanet** are welcome and encouraged. Feel free to fork the repository, make changes, and submit a Pull Request.

If you encounter any issues during use or have any suggestions for **CSUSTPlanet**, please feel free to open an Issue to let us know!

---

_Disclaimer: This project is intended solely for educational and technical research purposes. Please do not use it for any illegal activities. Please comply with your school's relevant network security regulations during use._
