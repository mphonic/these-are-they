~tatBufs = Environment.new;
~tatBufs.know = true;
~tatBufs.distort = [
    Buffer.alloc(s, 2048, 1, {|buf|
        buf.chebyMsg(Array.fill(64, {|i| (i % 2 == 0).if({ (i + 1).squared.reciprocal }, { 0.5.rand / (i + 1).squared }) }))
    }),
    Buffer.alloc(s, 2048, 1, {|buf|
        buf.chebyMsg(Array.fill(64, {|i| (i % 2 == 1).if({ (i + 1).reciprocal }, { 0.3.rand / (i + 1) }) }))
    }),
    Buffer.alloc(s, 2048, 1, {|buf|
        buf.chebyMsg(Array.fill(64, {|i| (i % 2 == 0).if({ (i + 1).squared.reciprocal }, { 0.5.rand / (i + 1).squared }) }))
    }),
    Buffer.alloc(s, 2048, 1, {|buf|
        buf.chebyMsg(Array.fill(64, {|i| (i % 2 == 1).if({ (i + 1).reciprocal }, { 0.5.rand / (i + 1) }) }))
    }),
    Buffer.alloc(s, 2048, 1, {|buf|
        buf.chebyMsg(Array.fill(64, {|i| (i % 2 == 0).if({ (i + 1).squared.reciprocal }, { 0.2.rand / (i + 1).squared }) }))
    });
];

s.sync;

~tatBufs.rec = Dictionary[
    \recEngines -> Buffer.alloc(s, s.sampleRate * 4, ~numChans),
    \recChipper -> Buffer.alloc(s, s.sampleRate * 4, 1),
    \recTalkers -> Buffer.alloc(s, s.sampleRate * 4, 1),
    \recAll -> Buffer.alloc(s, s.sampleRate * 4, ~numChans)
];

~tatBufs.sonks = (~docDir ++ "/audio/sonks/*")
.pathMatch
.select({|item| "^[.]".matchRegexp(item.split(Platform.pathSeparator).pop).not })
.collect({|item| (item.asSymbol++"*").pathMatch[0]})
.collect({|item, i| Buffer.read(s, item) });

~tatBufs.talkers = (~docDir ++ "/audio/talkers/*")
.pathMatch
.select({|item| "^[.]".matchRegexp(item.split(Platform.pathSeparator).pop).not })
.collect({|item| (item.asSymbol++"*").pathMatch[0]})
.collect({|item, i| Buffer.readChannel(s, item, channels: 0).normalize });

~tatBufs.ludes = (~docDir ++ "/audio/ludes/*")
.pathMatch
.select({|item| "^[.]".matchRegexp(item.split(Platform.pathSeparator).pop).not })
.collect({|item| (item.asSymbol++"*").pathMatch[0]})
.sort
.collect({|item, i| Buffer.cueSoundFile(s, item, numChannels: ~numChans, bufferSize: 2097152); });

~tatBufs.bombas = (~docDir ++ "/audio/bombas/*")
.pathMatch
.select({|item| "^[.]".matchRegexp(item.split(Platform.pathSeparator).pop).not })
.collect({|item| (item.asSymbol++"*").pathMatch[0]})
.sort
.collect({|item, i| Buffer.cueSoundFile(s, item, bufferSize: 262144) });

~tatBufs.chipPaths = (~docDir ++ "/audio/chips/*")
.pathMatch
.select({|item| "^[.]".matchRegexp(item.split(Platform.pathSeparator).pop).not })
.collect({|item| (item.asSymbol++"*").pathMatch[0]});

s.sync;

~tatBufs.vosc = [
    Buffer.allocConsecutive(32, s, 4096, 1, {|buf, i|
        var n, a;
        n = i + 1;
        a = Array.fill(n, {|j| ((j == i)).if({ 1 }, { (0.3.coin).if({ 0.9.rand.squared }) }) });
        buf.sine1Msg(a);
    }),
    Buffer.allocConsecutive(32, s, 4096, 1, {|buf, i|
        var n, a;
        n = i+1;
        a = Array.fill(n, {|j| ((j == i)).if({ 1 }, { (( j % 2 + 0.6 * 0.5).coin).if({ 0.9.rand.squared }) }) });
        buf.sine1Msg(a);
    }),
    Buffer.allocConsecutive(32, s, 4096, 1, {|buf, i|
        var n, a;
        n = i+1;
        a = Array.fill(n, { arg j; (j == 0).if({ 0.5.rand.squared }, { ((j % 2 == 0).and(j > 4)).if({ (j + 1).reciprocal }, { 0.25.rand }) });  });
        buf.sine1Msg(a);
    }),
    Buffer.allocConsecutive(32, s, 4096, 1, {|buf, i|
        var n, a;
        n = i+1;
        a = Array.fill(n, { arg j; (j == 0).if({ 0.5.rand.squared }, { ((j % 2 == 1).and(j > 4)).if({ (j + 1).reciprocal }, { 0.25.rand }) });  });
        buf.sine1Msg(a);
    })
];
~tatBufs.remakeVosc = {
    ~tatBufs.vosc[0].do({|e, i|
        var n, a;
        n = i + 1;
        a = Array.fill(n, {|j| ((j == i)).if({ 1 }, { (0.3.coin).if({ 0.9.rand.squared }) }) });
        e.sine1Msg(a);
    });
    ~tatBufs.vosc[1].do({|e, i|
        var n, a;
        n = i+1;
        a = Array.fill(n, {|j| ((j == i)).if({ 1 }, { (( j % 2 + 0.6 * 0.5).coin).if({ 0.9.rand.squared }) }) });
        e.sine1Msg(a);
    })
};