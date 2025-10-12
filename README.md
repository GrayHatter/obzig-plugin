# Zig OBS Plugin Shim

Building 
`zig build`
or
`zig build test`

Installing can be done directly by Zig build with
`zig build -p ~/.config/obs-studio/plugins/`
Otherwise you'll need to copy the artifacts from the zig-out/ directory.


# Building / Extending 
`src/cpp/qtdockwidget.moc` can be regenerated with `zig build regen-moc`.
Use `-Dmoc_path [path]` to specify a different moc binary location

### TODO
 - [x] add moc generation to build.zig
