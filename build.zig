const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const fs = std.fs;
const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // this code gets the git version hash and puts it in GitVersion.h
    // there is no currently no error checking ... yolo
    var code: u8 = undefined;
    const git_hash_untrimmed = b.execAllowFail(&[_][]const u8{
        "git",
        "-C",
        "src",
        "rev-parse",
        "HEAD",
    }, &code, .Ignore) catch {
        return;
    };
    const git_hash = mem.trim(u8, git_hash_untrimmed, " \n\r");
    const file = fs.cwd().createFile("src/GitVersion.h", .{ .read = true }) catch |err| {
        std.debug.print("Error opening GitVersion.h file: {any}", .{err});
        return;
    };
    file.writeAll(b.fmt("const char *gitversion = \"{s}\";", .{git_hash})) catch |err| {
        std.debug.print("Error writing to GitVersion.h: {any}", .{err});
        return;
    };

    // get the "builtin" system, aka the system we're compiling with
    const host_os = @tagName(builtin.os.tag);
    const host_arch = @tagName(builtin.cpu.arch);
    // assign the target variables if they were provide on the command line
    const target_os = if (target.os_tag) |os| @tagName(os) else "na";
    const target_arch = if (target.cpu_arch) |cpu| @tagName(cpu) else "na";
    const target_abi = if (target.abi) |abi| @tagName(abi) else "na";

    // output some debug info regarding the compile targets
    std.debug.print("Compiling on: {s}-{s}\n", .{ host_arch, host_os });
    // now the compile target to detect how we should set up library includes
    std.debug.print("Build target: {s}-{s}-{s}\n", .{ target_arch, target_os, target_abi });

    // Compiler flags taken from the original Makefile for mmvdmhost
    const mmdvm_cpp_cflags = [_][]const u8{
        "-g",
        "-O3",
        "-Wall",
        "-std=c++0x",
        "-pthread",
    };

    const mmdvmHost = b.addExecutable(.{
        .name = "MMDVMHost",
        .target = target,
        .optimize = optimize,
    });

    // Crete an array for the library dependencies
    var libs = ArrayList([]const u8).init(std.heap.page_allocator);
    defer libs.deinit();
    try libs.append("pthread");
    try libs.append("util");

    // Check if we are building for our native arch
    if (mem.eql(u8, target_arch, "na") or mem.eql(u8, host_arch, target_arch) and mem.eql(u8, host_os, target_os)) {
        // we're building for the same cpu and architecture as the host
        try libs.append("samplerate");
    } else {
        // building for a different architecture - TODO: add conditions for other arhcitectures
        // right now this only works for aarch64
        mmdvmHost.addIncludePath(.{ .path = "vendor/include" });
        mmdvmHost.addObjectFile(.{ .path = "vendor/lib/aarch64-linux-gnu/libsamplerate.so" });
    }

    // not sure if all of these are really needed, todo..
    mmdvmHost.linkLibC();
    mmdvmHost.linkLibCpp();
    //mmdvmHost.linkSystemLibrary("stdc++");

    const mmdvmhost_cpp_sources = [_][]const u8{
        "src/AMBEFEC.cpp",
        "src/BCH.cpp",
        "src/AX25Control.cpp",
        "src/AX25Network.cpp",
        "src/BPTC19696.cpp",
        "src/CASTInfo.cpp",
        "src/Conf.cpp",
        "src/CRC.cpp",
        "src/Display.cpp",
        "src/DMRControl.cpp",
        "src/DMRCSBK.cpp",
        "src/DMRData.cpp",
        "src/DMRDataHeader.cpp",
        "src/DMRDirectNetwork.cpp",
        "src/DMREMB.cpp",
        "src/DMREmbeddedData.cpp",
        "src/DMRFullLC.cpp",
        "src/DMRGatewayNetwork.cpp",
        "src/DMRLookup.cpp",
        "src/DMRLC.cpp",
        "src/DMRNetwork.cpp",
        "src/DMRShortLC.cpp",
        "src/DMRSlot.cpp",
        "src/DMRSlotType.cpp",
        "src/DMRAccessControl.cpp",
        "src/DMRTA.cpp",
        "src/DMRTrellis.cpp",
        "src/DStarControl.cpp",
        "src/DStarHeader.cpp",
        "src/DStarNetwork.cpp",
        "src/DStarSlowData.cpp",
        "src/FMControl.cpp",
        "src/FMNetwork.cpp",
        "src/Golay2087.cpp",
        "src/Golay24128.cpp",
        "src/Hamming.cpp",
        "src/I2CController.cpp",
        "src/IIRDirectForm1Filter.cpp",
        "src/LCDproc.cpp",
        "src/Log.cpp",
        "src/M17Control.cpp",
        "src/M17Convolution.cpp",
        "src/M17CRC.cpp",
        "src/M17LSF.cpp",
        "src/M17Network.cpp",
        "src/M17Utils.cpp",
        "src/MMDVMHost.cpp",
        "src/Modem.cpp",
        "src/ModemPort.cpp",
        "src/ModemSerialPort.cpp",
        "src/Mutex.cpp",
        "src/NetworkInfo.cpp",
        "src/Nextion.cpp",
        "src/NullController.cpp",
        "src/NullDisplay.cpp",
        "src/NXDNAudio.cpp",
        "src/NXDNControl.cpp",
        "src/NXDNConvolution.cpp",
        "src/NXDNCRC.cpp",
        "src/NXDNFACCH1.cpp",
        "src/NXDNIcomNetwork.cpp",
        "src/NXDNKenwoodNetwork.cpp",
        "src/NXDNLayer3.cpp",
        "src/NXDNLICH.cpp",
        "src/NXDNLookup.cpp",
        "src/NXDNNetwork.cpp",
        "src/NXDNSACCH.cpp",
        "src/NXDNUDCH.cpp",
        "src/P25Audio.cpp",
        "src/P25Control.cpp",
        "src/P25Data.cpp",
        "src/P25LowSpeedData.cpp",
        "src/P25Network.cpp",
        "src/P25NID.cpp",
        "src/P25Trellis.cpp",
        "src/P25Utils.cpp",
        "src/PseudoTTYController.cpp",
        "src/POCSAGControl.cpp",
        "src/POCSAGNetwork.cpp",
        "src/QR1676.cpp",
        "src/RemoteControl.cpp",
        "src/RS129.cpp",
        "src/RS241213.cpp",
        "src/RSSIInterpolator.cpp",
        "src/SerialPort.cpp",
        "src/SMeter.cpp",
        "src/StopWatch.cpp",
        "src/Sync.cpp",
        "src/SHA256.cpp",
        "src/TFTSurenoo.cpp",
        "src/Thread.cpp",
        "src/Timer.cpp",
        "src/UARTController.cpp",
        "src/UDPController.cpp",
        "src/UDPSocket.cpp",
        "src/UserDB.cpp",
        "src/UserDBentry.cpp",
        "src/Utils.cpp",
        "src/YSFControl.cpp",
        "src/YSFConvolution.cpp",
        "src/YSFFICH.cpp",
        "src/YSFNetwork.cpp",
        "src/YSFPayload.cpp",
    };
    // now add all the files to the list to be compiled
    mmdvmHost.addCSourceFiles(&mmdvmhost_cpp_sources, &mmdvm_cpp_cflags);

    for (libs.items) |lib_name| {
        mmdvmHost.linkSystemLibrary(lib_name);
    }

    // RemoteCommand executae
    //const remoteCommand = b.addExecutable("RemoteCommand", null);
    //remoteCommand.setTarget(target);
    //const remoteCommandSources = &[_][]const u8{
    //    "src/Log.cpp", "src/RemoteCommand.cpp", "src/UDPSocket.cpp",
    //};
    //for (remoteCommandSources) |file| {
    //    remoteCommand.addCxxFile(file);
    //}
    //for (globalLibPaths) |path| {
    //    remoteCommand.addLibPath(path);
    //}
    //for (globalLibs) |lib| {
    //    remoteCommand.linkSystemLibrary(lib);
    //}
    //remoteCommand.setOutputDir("zig-out/bin");

    // Set default steps
    b.default_step.dependOn(&mmdvmHost.step);
    //b.default_step.dependOn(&remoteCommand.step);

    b.installArtifact(mmdvmHost);
}
