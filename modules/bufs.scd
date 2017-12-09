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
    \recAll -> Buffer.alloc(s, s.sampleRate * 4, ~numChans),
    \waveset1 -> Buffer.alloc(s, s.sampleRate * 4, 1),
    \waveset2 -> Buffer.alloc(s, s.sampleRate * 4, 1)
];

~tatBufs.sonks = (~docDir ++ "/audio/sonks/*").pathMatch.collect({|item| (item.asSymbol++"*").pathMatch[0]}).collect({|item, i| Buffer.read(s, item) });

~tatBufs.talkers = (~docDir ++ "/audio/talkers/*").pathMatch.collect({|item| (item.asSymbol++"*").pathMatch[0]}).collect({|item, i| Buffer.readChannel(s, item, channels: 0).normalize });

~tatBufs.ludes = (~docDir ++ "/audio/ludes/*").pathMatch.collect({|item| (item.asSymbol++"*").pathMatch[0]}).sort.collect({|item, i| Buffer.cueSoundFile(s, item, numChannels: ~numChans, bufferSize: 2097152); });

~tatBufs.bombas = (~docDir ++ "/audio/bombas/*").pathMatch.collect({|item| (item.asSymbol++"*").pathMatch[0]}).sort.collect({|item, i| Buffer.cueSoundFile(s, item, bufferSize: 262144) });

~tatBufs.chipPaths = (~docDir ++ "/audio/chips/*").pathMatch.collect({|item| (item.asSymbol++"*").pathMatch[0]});

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
        a = Array.fill(n, { arg j; (j == 0).if({ 0.9.rand.squared }, { (j % 2 == 0).if({ (j + 1).reciprocal }, { 0 }) });  });
        buf.sine1Msg(a);
})];
~tatBufs.remakeVosc = {
    ~tatBufs.vosc[0].do({|e, i|
        var n, a;
        n = i + 1;
        a = Array.fill(n, {|j| ((j == i)).if({ 1 }, { (0.3.coin).if({ 0.9.rand.squared }) }) });
        e.sine1Msg(a);
    });
};