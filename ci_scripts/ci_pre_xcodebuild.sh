#!/bin/sh

# macroの使用許諾のアラートをスキップするために設定
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# GoogleService-Info.plistをXcode Cloudの環境変数より生成
echo $GOOGLE_SERVICE_INFO > ../RelNet/App/GoogleService-Info.plist
