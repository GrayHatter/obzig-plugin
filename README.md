# Zig OBS Plugin Shim

Building 
`zig build`
or
`zig build test`

Installing can be done directly by Zig build with
`zig build -p ~/.config/obs-studio/plugins/`
Otherwise you'll need to copy the artifacts from the zig-out/ directory.


# Building / Extending
you may have to manually run 
`/usr/lib/qt6/moc src/cpp/qtdockwidget.h -o src/cpp/qtdockwidget.moc`
if you're updating the QTDock helper.

### TODO
 - [ ] add moc generation to build.zig
