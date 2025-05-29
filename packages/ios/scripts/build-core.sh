#!/bin/sh

REPO_ROOT=/Users/klolev/src/cloclo/gamegirl

cd $REPO_ROOT/packages/core \
  && cargo build --release --target=aarch64-apple-ios \
  && cargo build --release --target=aarch64-apple-ios-sim \
  && cargo build --release --target=aarch64-apple-darwin \
  && cd ../uniffi-bindgen \
  && cargo run generate ../core/src/bindings.udl -l swift --out-dir ../core/target/ios-bindings \
  && cd ../core \
  && mv target/ios-bindings/gamegirl_coreFFI.modulemap target/ios-bindings/module.modulemap \
  && rm -rf target/GameGirlCore.xcframework \
  && xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/libgamegirl_core.a \
    -headers target/ios-bindings \
    -library target/aarch64-apple-ios-sim/release/libgamegirl_core.a \
    -headers target/ios-bindings \
    -library target/aarch64-apple-darwin/release/libgamegirl_core.a \
    -headers target/ios-bindings \
    -output target/GameGirlCore.xcframework
