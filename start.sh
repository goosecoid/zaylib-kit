#!/usr/bin/env sh

RAYLIB_URL=""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    RAYLIB_URL="https://github.com/raysan5/raylib/releases/download/5.0/raylib-5.0_linux_amd64.tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    RAYLIB_URL="https://github.com/raysan5/raylib/releases/download/5.0/raylib-5.0_macos.tar.gz"
else
    echo "Unsupported OS, only linux-gnu and darwin are supported. Aborting..."
fi

PROJECT_NAME=$1

if [ -z "$1" ]; then
    PROJECT_NAME="hello_world"
fi

mkdir "$PROJECT_NAME"

cd "$PROJECT_NAME"

read -r -d '' BUILD_FILE <<EOF

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "$PROJECT_NAME",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.addObjectFile(
        switch (target.result.os.tag) {
            .linux => b.path("raylib/lib/libraylib.a"),
            .macos => b.path("raylib/lib/libraylib.a"),
            // TODO: add other OS'es
            else => @panic("Unsupported OS"),
        }
    );
    exe.addIncludePath(b.path("raylib/include"));

    switch (target.result.os.tag) {
        .linux => {},
        .macos => {
            exe.linkFramework("Cocoa");
            exe.linkFramework("OpenGL");
            exe.linkFramework("CoreAudio");
            exe.linkFramework("CoreVideo");
            exe.linkFramework("IOKit");
        },
        // TODO: add other OS'es
        else => @panic("Unsupported OS"),
    }


    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
       run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

EOF

echo "$BUILD_FILE" >build.zig

mkdir src

cd src

read -r -d '' HELLO_WORLD <<EOF

const r = @cImport({
    @cInclude("raylib.h");
});

pub fn main() void {
    const w = 800;
    const h = 450;

    r.InitWindow(w, h, "[raylib] Hello World!");
    defer r.CloseWindow();

    r.SetTargetFPS(60);

    while(!r.WindowShouldClose()) {
        r.BeginDrawing();

            r.ClearBackground(r.RAYWHITE);
            r.DrawText("Hello, World!", 200,  h / 2, 20, r.BLACK);

        r.EndDrawing();
    }
}
EOF

echo "$HELLO_WORLD" >main.zig

cd ..

wget "$RAYLIB_URL"

tar -xvf raylib-*
rm raylib-*.tar.gz

mv raylib-* raylib
