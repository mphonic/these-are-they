// the synthdefs
SynthDef(\recordIt, {|in = 0, bombin = 56, run = 0, recBuf = 0|
    var sig = In.ar(in, ~numChans), bomba = In.ar(bombin, ~numChans);
    sig = Compander.ar(sig, bomba, 0.1, 1, 0.1, 0.3, 0.5);
    RecordBuf.ar(MoogFF.ar(sig, Gendy4.kr(minfreq: 0.01, maxfreq: 0.1).clip2(1.0).exprange(400, 8000.0), LFNoise2.kr(0.2).range(0.7, 3.0), mul: 2.0), recBuf, 0, 0.5, 0.6, run, loop: 1);
    ReplaceOut.ar(0, sig + bomba);
}).send(s);

SynthDef(\spitter, {|out = 0, shapeBuf, buf|
    var sig, fade = Rand(2, 8.0);
    sig = LeakDC.ar(
        Shaper.ar(shapeBuf,
            PlayBuf.ar(
                ~numChans,
                buf,
                EnvGen.kr(Env([0.5, 0.25], [Rand(2, 8.0)], [Rand(-8.0, 8.0)])) * TWChoose.kr(Impulse.kr(0), [-1, 1, 2, -2], [0.7, 0.1, 0.1, 0.1]) * BufRateScale.kr(buf),
                loop: 1
            ) *
            EnvGen.kr(Env([0.0,1,0],[0.3, fade]), doneAction: 2)
        )
    ) *
    EnvGen.kr(Env([0,1,1,0], [0.067, fade - 0.367, 0.067]));
    Out.ar(out, sig);
}).send(s);

(~numChans == 4).if({
    SynthDef(\talkyVosc, {|fmul = 1, rmul = 1, rootbuf = 0, recBuf = 0, out = 32|
        var a, b, amp, changer, ch, at;
        changer = Gendy5.kr(minfreq: 0.1 * rmul, maxfreq: 1.2 * rmul).clip2(1.0).range(-120.0, 120);
        ch = HPZ1.kr(changer);
        at = Dust.kr(1.9 * rmul);
        a=VOsc.ar(rootbuf + Gendy1.kr(minfreq: 0.06.dup(~numChans), maxfreq: 0.7.dup(~numChans), ampscale: 0.1, knum: 8).clip2(1.0).range(0, 31), (TIRand.kr(15, 59, at).midicps * fmul).lag(0.1), mul: EnvGen.kr(Env([0,1,1,0], [0.067, TWChoose.kr(at, [0.3,0.2,0.1],[0.8, 0.1, 0.1]), 0.3]), at) * 0.4);
        b=a/4+LocalIn.ar(~numChans);
        b=LeakDC.ar(if(TExpRand.kr(0.01,1,at), FreqShift.ar(b,changer), b));
        amp = Amplitude.kr([b[0], b[1]].mean, 0.1, 0.1);
        SendTrig.kr(amp < 0.000008, 1000, amp);
        // b = Splay.ar(b, LFNoise2.kr(0.5).range(0, 1));
        LocalOut.ar(DelayC.ar(b,1,Ramp.kr(TWChoose.kr(at, [0.095, 0.17], [0.8, 0.2]), 0.3),0.9 * EnvGen.kr(Env.asr(0.067, 1, 0.3), SetResetFF.kr(Dust.kr(6 * rmul), ch))));
        RecordBuf.ar(b * 0.9, recBuf, loop: 1);
        b = [Splay.ar([b[0], b[1]], LFNoise2.kr(0.5).range(0, 1)), Splay.ar([b[2], b[3]], LFNoise2.kr(0.5).range(0, 1))].flatten;
        Out.ar(out, if(LFNoise2.kr(0.5).range(0, 1.0).squared, b, a * 0.25));
    }).send(s);

    SynthDef(\chopTalk, {|freq=0.5, grain=1.0, chop_rate=0.7, chop_depth=0, amp=0.2, recBuf = 0, out=32|
        var sig,wup,squaryness,trig,changer,chsel, ch;
        changer = Gendy5.kr(minfreq: 0.1.dup(~numChans), maxfreq: 1.2.dup(~numChans)).clip2(1.0);
        ch = HPZ1.kr(changer);
        chsel = changer.range(0.0, 2).round;
        trig=Dust.kr(chop_depth.linexp(0.0,1.0,1.9,8.2));
        wup=Select.kr(chsel,[TExpRand.kr(0.01, 0.175, trig: trig),TExpRand.kr(0.01, 0.086, trig: trig),TExpRand.kr(0.02, 0.03, trig: trig).ring1(amp * 0.5)]);
        squaryness=TBrownRand.kr(0.1, 1.22, 0.5, trig: Dust.kr(4 * 1.8125)).min(1.0);
        sig=LeakDC.ar(Fhn2DL.ar(33075, 44100,
            wup,
            wup * Select.kr(chsel,[freq.linlin(1,0.0,0.1,1.0),freq.linlin(1,0.0,0.25,1.0),freq.linlin(1,0.0,0.9,1.0)]),
            Select.kr(chsel,[amp.linexp(1,0.0,0.1, 0.5),amp.linexp(1,0.0,0.4, 0.5),amp.linexp(1,0.0,0.65, 0.75)]),
            chop_rate.linlin(0,1.0,1.5, 1.9),
            chop_depth.linlin(0,1.0,-0.5, 0.5),
            mul:amp.ring1(1.0 - squaryness))).tanh
        * SetResetFF.kr(Dust.kr(6), ch);
        sig=sig + LocalIn.ar(~numChans);
        SendTrig.ar(DetectSilence.ar([sig[0], sig[1]].mean, 0.001, 0.05), 1000, 0);
        sig = BPeakEQ.ar(BPeakEQ.ar(sig, 2130, 0.0004, -2.5), 5440, 0.0013, -1.1);
        // sig = BPeakEQ.ar(BPeakEQ.ar(sig, 2130, 0.5689, -2.5), 5440, 0.48286, -1.1);
        sig=if(TExpRand.kr(0.01,1,trig), FreqShift.ar(sig,changer.range(-120,120)), sig);
        LocalOut.ar(DelayC.ar(sig, 1, Ramp.kr(TWChoose.kr(trig, [0.095, 0.17], [0.8, 0.2]), 0.3), 0.9*EnvGen.kr(Env.asr(0.067, 1, 0.3), SetResetFF.kr(Dust.kr(4), ch))));
        RecordBuf.ar(sig * 0.8, recBuf, loop: 1);
        Out.ar(out, [Splay.ar([sig[0], sig[1]], LFNoise2.kr(0.5).range(0, 1)),Splay.ar([sig[2], sig[3]], LFNoise2.kr(0.5).range(0, 1))].flatten);
    }).send(s);

    SynthDef(\uncommon, {|in1 = 32, in2 = 36, amp = 1, recBuf = 0, forgettingDistance = 0.1, out = 0|
        var i1, i2, chain1, chain2, chain, trig, timescale, pitchenv, modenv, forgettor;
        i1 = In.ar(in1, ~numChans) * 2;
        i2 = In.ar(in2, ~numChans);
        RecordBuf.ar(i2.mean, recBuf, loop: 1);
        i2 = i2 * EnvDetect.ar(i1, 0.01, 0.1) * 1.75;
        // i1 = LPF.ar(i1, 2200);
        i1 = Compander.ar(i1, i1, 0.11, slopeBelow: 10, slopeAbove: 1, clampTime: 0.01, relaxTime: 0.01);
        chain1 = FFT({LocalBuf(1024)}.dup(~numChans), DelayN.ar(i1, 0.3333, 0.3333));
        chain2 = FFT({LocalBuf(1024)}.dup(~numChans), i2);
        chain = PV_XFade(chain2, chain1, [LFNoise1.kr(0.5, 0.6).squared.max(0.008).dup, LFNoise1.kr(0.3, 0.6).squared.max(0.008).dup].flatten.squared);
        // "forgetting" sound
        // forgettingDistance = LFBrownNoise2.kr(1, 0.366).range(0.2, 0.7);
        trig = CoinGate.kr(forgettingDistance.linlin(0, 1.0, 0, 0.6), Dust.kr(forgettingDistance.linexp(0, 1.0, 0.05, 0.2)));
        timescale = TRand.kr(1.0, forgettingDistance.linlin(0, 1.0, 0.5, 2.83), trig);
        pitchenv = EnvGen.kr(Env([1, 1, 0.5], [0, 3], [0, \exp]), gate: trig, timeScale: timescale);
        modenv = EnvGen.kr(Env([0,0,1,0.8,0.8,0],[0,0.8,0.2,0.5,1.5]), gate: trig, timeScale: timescale);
        forgettor = PMOsc.ar(TExpRand.kr(55, 100.0, trig.dup(4)), TExpRand.kr(30.0, 50, trig.dup(4)) * pitchenv, modenv, mul: modenv.squared * 0.2).softclip + LPF.ar(BrownNoise.ar(0.4.dup), TExpRand.kr(80, 140.0, trig.dup(4)), modenv);
        Out.ar(out, (modenv.squared * forgettor * 0.6 + (1 - modenv * IFFT(chain))) * amp.lag(0.1));
    }).send(s);
}, {
    SynthDef(\talkyVosc, {|fmul = 1, rmul = 1, rootbuf = 0, recBuf = 0, out = 32|
        var a, b, amp, changer, ch, at;
        changer = Gendy5.kr(minfreq: 0.1 * rmul, maxfreq: 1.2 * rmul).clip2(1.0).range(-120.0, 120);
        ch = HPZ1.kr(changer);
        at = Dust.kr(1.9 * rmul);
        a=VOsc.ar(rootbuf + Gendy1.kr(minfreq: 0.06.dup(~numChans), maxfreq: 0.7.dup(~numChans), ampscale: 0.1, knum: 8).clip2(1.0).range(0, 31), (TIRand.kr(15, 59, at).midicps * fmul).lag(0.1), mul: EnvGen.kr(Env([0,1,1,0], [0.067, TWChoose.kr(at, [0.3,0.2,0.1],[0.8, 0.1, 0.1]), 0.3]), at) * 0.4);
        b=a/4+LocalIn.ar(~numChans);
        b=LeakDC.ar(if(TExpRand.kr(0.01,1,at), FreqShift.ar(b,changer), b));
        amp = Amplitude.kr([b[0], b[1]].mean, 0.1, 0.1);
        SendTrig.kr(amp < 0.000008, 1000, amp);
        b = Splay.ar(b, LFNoise2.kr(0.5).range(0, 1));
        LocalOut.ar(DelayC.ar(b,1,Ramp.kr(TWChoose.kr(at, [0.095, 0.17], [0.8, 0.2]), 0.3),0.9 * EnvGen.kr(Env.asr(0.067, 1, 0.3), SetResetFF.kr(Dust.kr(6 * rmul), ch))));
        RecordBuf.ar(b * 0.9, recBuf, loop: 1);
        // b = [Splay.ar(b[0], b[1], LFNoise2.kr(0.5).range(0, 1)), Splay.ar(b[2], b[3], LFNoise2.kr(0.5).range(0, 1))].flatten;
        Out.ar(out, if(LFNoise2.kr(0.5).range(0, 1.0).squared, b, a * 0.25));
    }).send(s);

    SynthDef(\chopTalk, {|freq=0.5, grain=1.0, chop_rate=0.7, chop_depth=0, amp=0.2, recBuf = 0, out=32|
        var sig,wup,squaryness,trig,changer,chsel, ch;
        changer = Gendy5.kr(minfreq: 0.1.dup(~numChans), maxfreq: 1.2.dup(~numChans)).clip2(1.0);
        ch = HPZ1.kr(changer);
        chsel = changer.range(0.0, 2).round;
        trig=Dust.kr(chop_depth.linexp(0.0,1.0,1.9,8.2));
        wup=Select.kr(chsel,[TExpRand.kr(0.01, 0.175, trig: trig),TExpRand.kr(0.01, 0.086, trig: trig),TExpRand.kr(0.02, 0.03, trig: trig).ring1(amp * 0.5)]);
        squaryness=TBrownRand.kr(0.1, 1.22, 0.5, trig: Dust.kr(4 * 1.8125)).min(1.0);
        sig=LeakDC.ar(Fhn2DL.ar(33075, 44100,
            wup,
            wup * Select.kr(chsel,[freq.linlin(1,0.0,0.1,1.0),freq.linlin(1,0.0,0.25,1.0),freq.linlin(1,0.0,0.9,1.0)]),
            Select.kr(chsel,[amp.linexp(1,0.0,0.1, 0.5),amp.linexp(1,0.0,0.4, 0.5),amp.linexp(1,0.0,0.65, 0.75)]),
            chop_rate.linlin(0,1.0,1.5, 1.9),
            chop_depth.linlin(0,1.0,-0.5, 0.5),
            mul:amp.ring1(1.0 - squaryness))).tanh
        * SetResetFF.kr(Dust.kr(6), ch);
        sig=sig + LocalIn.ar(~numChans);
        SendTrig.ar(DetectSilence.ar([sig[0], sig[1]].mean, 0.001, 0.05), 1000, 0);
        sig = BPeakEQ.ar(BPeakEQ.ar(sig, 2130, 0.0004, -2.5), 5440, 0.0013, -1.1);
        // sig = BPeakEQ.ar(BPeakEQ.ar(sig, 2130, 0.5689, -2.5), 5440, 0.48286, -1.1);
        sig=if(TExpRand.kr(0.01,1,trig), FreqShift.ar(sig,changer.range(-120,120)), sig);
        LocalOut.ar(DelayC.ar(sig, 1, Ramp.kr(TWChoose.kr(trig, [0.095, 0.17], [0.8, 0.2]), 0.3), 0.9*EnvGen.kr(Env.asr(0.067, 1, 0.3), SetResetFF.kr(Dust.kr(4), ch))));
        RecordBuf.ar(sig * 0.8, recBuf, loop: 1);
        Out.ar(out, Splay.ar(sig, LFNoise2.kr(0.5).range(0, 1)));
    }).send(s);

    SynthDef(\uncommon, {|in1 = 32, in2 = 36, amp = 1, recBuf = 0, forgettingDistance = 0.1, out = 0|
        var i1, i2, chain1, chain2, chain, trig, timescale, pitchenv, modenv, forgettor;
        i1 = In.ar(in1, ~numChans) * 2;
        i2 = In.ar(in2, ~numChans);
        RecordBuf.ar(i2.mean, recBuf, loop: 1);
        i2 = i2 * EnvDetect.ar(i1, 0.01, 0.1) * 1.75;
        // i1 = LPF.ar(i1, 2200);
        i1 = Compander.ar(i1, i1, 0.11, slopeBelow: 10, slopeAbove: 1, clampTime: 0.01, relaxTime: 0.01);
        chain1 = FFT({LocalBuf(1024)}.dup(~numChans), DelayN.ar(i1, 0.3333, 0.3333));
        chain2 = FFT({LocalBuf(1024)}.dup(~numChans), i2);
        chain = PV_XFade(chain2, chain1, LFNoise2.kr(0.5, 0.5, 0.05).max(0.01).squared);
        // forgettingDistance = LFBrownNoise2.kr(1, 0.366).range(0.2, 0.7);
        trig = CoinGate.kr(forgettingDistance.linlin(0, 1.0, 0, 0.6), Dust.kr(forgettingDistance.linexp(0, 1.0, 0.05, 0.2)));
        timescale = TRand.kr(1.0, forgettingDistance.linlin(0, 1.0, 0.5, 2.83), trig);
        pitchenv = EnvGen.kr(Env([1, 1, 0.5], [0, 3], [0, \exp]), gate: trig, timeScale: timescale);
        modenv = EnvGen.kr(Env([0,0,1,0.8,0.8,0],[0,0.8,0.2,0.5,1.5]), gate: trig, timeScale: timescale);
        forgettor = PMOsc.ar(TExpRand.kr(55, 100.0, trig.dup), TExpRand.kr(30.0, 50, trig.dup) * pitchenv, modenv, mul: modenv.squared * 0.2).softclip + LPF.ar(BrownNoise.ar(0.4.dup), TExpRand.kr(80, 140.0, trig.dup), modenv);
        Out.ar(out, (modenv.squared * forgettor * 0.6 + (1 - modenv * IFFT(chain))) * amp.lag(0.1));
    }).send(s);
});

SynthDef(\talkySquid, {|freq=44100, grain=1.0, pan=0, amp=1, rscale=1,nrate=5,mrate=4,recBuf = 0, out=72|
    var sig,wup,squaryness;
    wup=TExpRand.kr(0.01, 0.175, trig: Dust.kr(mrate * 2));
    squaryness=TBrownRand.kr(0.1, 1.22, 0.5, trig: Dust.kr(mrate * 1.8125)).min(1.0);
    sig=LeakDC.ar(Fhn2DL.ar(freq * grain, freq,
        wup,
        wup * squaryness,
        Fhn2DN.kr(mrate, mrate * 12, LFNoise0.kr(nrate).range(0.001, 0.2), LFNoise0.kr(nrate).range(0.001, 0.2)).range(0.1, 0.4),
        Fhn2DN.kr(mrate, mrate * 12, LFNoise0.kr(nrate).range(0.001, 0.2), LFNoise0.kr(nrate).range(0.001, 0.2)).range(1.5, 1.9),
        Fhn2DN.kr(mrate, mrate * 2, LFNoise0.kr(nrate).range(0.001, 0.2), LFNoise0.kr(nrate).range(0.001, 0.2)).range(-0.5, 0.5),
        mul:amp.ring1(1.0 - squaryness)));
    SendTrig.kr(Amplitude.kr(sig, 0.1, 0.1) < 0.00005, 1001, mrate);
    sig = (sig * 1.5).softclip;
    // sig = sig.softclip;
    RecordBuf.ar(sig, recBuf, loop: 1);
    Out.ar(out, sig);
}).send(s);

SynthDef(\offOnSite, {|amp=0.83, mute=0, recBuf=0, shapeBuf=1, out=101|
	var trig, sig, pitch, hasFreq, ft1, ft2, ft3, ft4, freqs, freq;
	trig = Dust.kr(2);
    #ft1, ft2, ft3, ft4 = Dust.kr(3.dup(4));
    freqs = [TChoose.kr(ft1, 96.dup(rrand(13, 21)) ++ 79.dup(rrand(3, 5))), TChoose.kr(ft2, 24.dup(rrand(8, 17)) ++ 19.dup(rrand(4, 7)))];
    freqs = freqs + TChoose.kr(CoinGate.kr(0.8,ft3), [-3, -2, 0, 1, 3, 5, 7, 9, 10]);
    freq = TWChoose.kr(ft4, freqs, [0.33, 0.77]).midicps;
	freq = VarLag.kr(freq, TRand.kr(0.067, 0.25, trig));
	sig = Mix.fill(3, {
		Mix([
			LFTri.ar(freq.ring1(rrand(-0.01, 0.015))),
			VarSaw.ar(freq.ring1(rrand(-0.01, 0.015)), 0, LFTri.kr(0.12).range(0.01, 0.99)),
			SyncSaw.ar(freq.ring1(rrand(-0.01, 0.015)), freq.ring1(LFTri.kr(0.1).cubed + 1) * 2)
		]);
	});
	sig = MoogLadder.ar(sig, 18000, 0);
	sig = LeakDC.ar(Shaper.ar(
		shapeBuf,
		sig
	));
    amp = amp * TWChoose.kr(ft4, [0, 1], [0.2, 0.8]);
	RecordBuf.ar(sig * 0.55, recBuf, loop: 1);
	//#pitch, hasFreq = Pitch.kr(sig, minFreq: 40);
    SendTrig.kr(Amplitude.kr(sig * amp.lag(0.01), 0.02, 0.067) < 0.0001, 1001, 0);
	//Pan2.ar(sig, 0, (1-mute).lag(0.067) * amp.lag(0.067));
    Out.ar(out, sig * amp);
}).send(s);

SynthDef(\bufSticker, {|out = 36, bufnum, amp = 1, rate = 1, pan = 0, repRate = 0, posGate = 0|
    var read, sig, smear, resetPos, phaseOut, trigem;
    resetPos = A2K.kr(LocalIn.ar(1));
    resetPos = Latch.kr(resetPos, posGate);
    trigem = Impulse.kr(repRate);
    read = Phasor.ar(trigem, BufRateScale.kr(bufnum) * rate, 0, BufFrames.kr(bufnum), resetPos);
    LocalOut.ar(read);
    sig=DelayC.ar(BufRd.ar(1, bufnum, read, 1, 4), 0.067, 0.067) * (1 - trigem).lag(0.067);
    // smear = Mix(FreqShift.ar(sig, { ExpRand(20, 440.0) * TChoose.kr(Impulse.kr(0), [-1, 1]) }.dup(4), mul: 0.4));
    smear = SMS.ar(sig, noisefloor: 0.05, freqmult: LFNoise0.kr(0.2).range(-12, 12).midiratio, formantpreserve: 1);
    smear = if(LFNoise1.kr(LFNoise0.kr(0.3).exprange(0.15, 0.45)).exprange(0.01, 1.0), sig, smear[1] * LFNoise1.kr(0.1).range(0.2, 0.4) + smear[0] * 4);
    Out.ar(out,
        Pan2.ar(
            if(LFNoise2.kr(LFNoise0.kr(0.3).exprange(0.15, 0.45), 0.5, 0.288).max(0).round.lag(0.2), LPF.ar(LeakDC.ar(Squiz.ar(sig, LFNoise1.kr(0.4).exprange(0.9, 1.5).squared.max(1), 1)), 10000), smear),
            pan,
            amp
        )
    )
}).send(s);

SynthDef(\saddy, {|rate=0.5, spread=1.0, bufnum=0, gate=0, spgate=0, amp=1, out=0|
    var i, chain, cep, fftbuf, n1, n2, o, e, sp;
    e = EnvGen.kr(Env.asr(1.0, 1, 3), gate);
    sp = EnvGen.kr(Env.asr(1.0, 1, 3), spgate);
    i = LeakDC.ar(PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * rate.lag(0.2) * sp, loop: 1));
    n1 = LFBrownNoise1.kr(1, 0.5, 1);
    n2 = LFBrownNoise1.kr(1, 0.5, 1);
    //i = [SMS.ar(i[0], freqmult: n1.lincurve(-1.0, 1.0, 1, 0.69, 2), useifft: 1)[0], SMS.ar(i[1], freqmult: n1.lincurve(-1.0, 1.0, 1, 0.55, 2), useifft: 1)[0]];

    i = Splay.ar(DelayC.ar(PitchShift.ar(i * amp.lag(1), 0.2, n1.lincurve(-1.0, 1.0, 1, [0.75, 0.65], 2), timeDispersion: { ExpRand(0.001, 0.005) }.dup), 0.125, { Rand(0.02, 0.125) }.dup * n1.range(0, 1.0).squared), spread) * n2.range(0.4, 1).squared;
    //i = Splay.ar(DelayC.ar(i, 0.125, { Rand(0.02, 0.125) }.dup * n1.range(0, 1.0).squared), spread);
    fftbuf = { LocalBuf(2048, 1) }.dup;
    chain = FFT(fftbuf, i);
    cep = Cepstrum({ LocalBuf(1024, 1) }.dup, chain);
    //cep = PV_BinShift(cep, 1, n1.lincurve(-1.0, 1.0, 0, [-4, -4.5], 2), 1);
    cep = PV_MagSmear(cep, n1.exprange(0.05, 30));
    chain = ICepstrum(cep, fftbuf);
    o = IFFT(chain);
    o = o.softclip * e;
    o = Splay.ar(o, amp.min(0.8).linlin(0, 0.8, 0.2, 1.0), 1, n1 * amp.min(1).linlin(1.0, 0, 0, 1), false);
    Out.ar(out, PanAz.ar(~numChans, o[0], LFNoise2.kr(0.2).range(-0.3, -0.6)) + PanAz.ar(~numChans, o[1], LFNoise2.kr(0.2).range(0.3, 0.6)));
}).send(s);

SynthDef(\bufbuf2, {|out = 0, buf = 0, rate = 1, at = 0.01, dur = 1, dec = 0.1, pos = 0, panModSpeed = 0, amp = 0.1, panPos = 0, panAmt = 1|
    var sample, panT, env, aux, size, bufplay, w, x, y;
    sample = PlayBuf.ar(2, buf, rate*BufRateScale.kr(buf), 1, pos*BufFrames.kr(buf)*2, 1);
    panT = panPos+(FSinOsc.kr(panModSpeed)*panAmt);
    env = EnvGen.ar(Env([0, 1, 1, 0], [at, dur, dec]), doneAction: 2);
    SendTrig.ar(1-Trig.ar(Impulse.ar(0),at+dur+dec-0.01), 1003, buf);
    #w, x, y = BiPanB2.ar(sample[0], sample[1], panT);
    Out.ar(out, DecodeB2.ar(~numChans, w, x, y) * env);
}).send(s);

SynthDef(\bufbuf1, {|out = 0, buf = 0, rate = 1, at = 0.01, dur = 1, dec = 0.1, pos = 0, panModSpeed = 0, amp = 0.1, panPos = 0, panAmt = 1|
    var sample, panT, env, aux, size, bufplay;
    sample = PlayBuf.ar(1, buf, rate*BufRateScale.kr(buf), 1, pos*BufFrames.kr(buf), 1);
    panT = panPos+(FSinOsc.kr(panModSpeed)*panAmt);
    env = EnvGen.ar(Env([0, 1, 1, 0], [at, dur, dec]), doneAction: 2);
    SendTrig.ar(1-Trig.ar(Impulse.ar(0),at+dur+dec-0.01), 1003, buf);
    Out.ar(out, PanAz.ar(~numChans, sample, panT) * amp);
}).send(s);

SynthDef(\bitOBuf, {|out = 0, buf, modfreq, modstart, modend, rates = #[0,0,0,0], starts = #[0,0,0,0], ends = #[0,0,0,0], amp, dur=1, dec = 1, shapeBuf|
    var amod, sig, env;
    amod = BufRd.kr(1, buf,
        Phasor.ar(0, modfreq * BufRateScale.kr(buf), modstart, modend)) * Rand(1.0, 2.0);
    env = EnvGen.kr(Env([0, 1, 1, 0], [Rand(0.067,1),dur,dec], [-3, 0, 2]), doneAction: 2);
    sig = Mix.fill(4, {|i|
        BufRd.ar(1, buf,
            Phasor.ar(0, (rates[i]).ring1(amod) * BufRateScale.kr(buf) * TWChoose.kr(Impulse.kr((dur + 3).reciprocal), [env, 1], [0.1, 0.9]), starts[i], ends[i])) * 0.333
    }).ring1(amod) * Rand(0.83, 0.975).squared * amp;
    sig = LeakDC.ar(Shaper.ar(shapeBuf, LeakDC.ar(sig)));
    Out.ar(out, PanAz.ar(~numChans, sig * env, Rand(-1.0, 1.0), 0.7).softclip);
}).send(s);

/*SynthDef(\mouth, {|amp=1, f=3305, fr=0.25, fd=0.2, ar=4, ad=0.9, a=0.1, b=0.1, c=0.2, d=0.2, dur = 1, gate=1, fade=3, pan=0, shapeBuf=0, out=0|
	var sig, env, fmod, amod;
	fr = fr.lag(Rand(1.0,3.0));
	fd = fd.lag(Rand(0.9, 2.0));
	ar = ar.lag(Rand(1.0, 3.0));
	ad = ad.lag(Rand(0.9, 2.0));
	fmod = Select.kr(TIRand.kr(0,2,gate), [LFNoise2.kr(fr, fd), LFSaw.kr((fr * 2).ring1(LFNoise1.kr(fr, 0.5)), 1, fd * TChoose.kr(gate, [-1, 1])), Gendy4.kr(minfreq: fr * 0.041, maxfreq: fr * 0.16, ampscale: 0.25, durscale: 0.9).clip2(1.0) * fd * ToggleFF.kr(Dust.kr(fr * 0.4)).lag(Rand(0.5, 1.5))]);
	amod = Select.kr(TIRand.kr(0,1,gate), [LFNoise2.kr(ar, ad), Gendy4.kr(minfreq: ar * 0.041, maxfreq: ar * 0.16, ampscale: 0.25, durscale: 0.9).clip2(1.0) * ad  * ToggleFF.kr(Dust.kr(ar * 0.5)).lag(Rand(0.5, 1.5))]);
	sig=OnePole.ar(
		LeakDC.ar(
			Shaper.ar(
				shapeBuf,
				LeakDC.ar(
					Fhn2DL.ar(
						60,
                        f.lag(Rand(0.9, 3.0)).ring1(fmod).max(60).min(48000),
						a.lag(Rand(0.9, 1.7)),
						b.lag(Rand(0.9, 1.8)),
						c.lag(Rand(0.9, 1.4)),
						d.lag(Rand(1.0, 3.0)),
						mul:amp.min(1).lag(Rand(1.0, 3.0)).ring1(amod)
					)
				)
			)
		),
		Rand(0.5, 0.81)
	).tanh;
    env=EnvGen.kr(Env([0,1,1,0], [fade,dur,fade]), doneAction: 2);
	Out.ar(out, PanAz.ar(~numChans, sig * env, pan));
}).send(s);*/