(
s.options.numInputBusChannels = 18;
s.options.numOutputBusChannels = 18;
s.options.memSize = 524288;
s.options.sampleRate = 48000;
s.options.zeroConf = false;
s.options.device = "ASIO : ASIO Fireface USB";
s.waitForBoot({
    var go, no, w, butt;

    ~docDir = Document.current.dir;
    ~numChans = 2;

    // setup buffers and paths for vosc, samples, interludes, etc.
    Buffer.freeAll;
    s.sync;
    (~docDir ++ "/modules/bufs.scd").loadPaths;

    "Loading Buffers".postln;
    s.sync;
    "Buffers Loaded".postln;

    (~docDir ++ "/modules/synths.scd").loadPaths;

    "Loading Synths".postln;
    s.sync;
    "Synths Loaded".postln;

    // do it
    go = {
        // holdIt pauses "listening" for silences, slowing down the stream of "reactions"
        // governor modifies the probability of reactions and can also serve to slow them down
        // irritation is the probability of a "foire" occuring durring an engine silence
        // its value also affects the length of a foire event
        var synths, streams, bomba, outs, holdIt = true, irritation=0.164, governor = 1;
        "Off we go".postln;

        // output busses for the synths
        outs = Dictionary[
            \saddy -> 0,
            \foire -> 0,
            \spitter -> 0,
            \chipper -> 0,
            \talker -> 0,
            \lude -> 0,
            \mouth -> 0,
            // these have internal routing, so just be aware of where you're sending them
            \sticker1 -> 36,
            \sticker2 -> 38,
            \engine -> 32,
            \bomba -> 56
        ];
        (~numChans < 3).if({ // sticker2 should only be different from sticker1 if multichannel
            outs[\sticker2] = outs[\sticker1];
        });

        // streams for buffers of different sorts
        streams = Dictionary[
            \sonks -> Pseq(~tatBufs.sonks, inf).asStream,
            \talkers -> Pseq(~tatBufs.talkers.scramble, inf).asStream,
            \bombas -> Pseq(~tatBufs.bombas, inf).asStream
        ];

        { 1.0.wait; holdIt = false }.fork;

        // play synths
        synths = Dictionary[
            \record -> Synth(\recordIt, [\recBuf, ~tatBufs.rec[\recAll].bufnum]),
            \uncommon -> Synth(\uncommon, [\out, outs[\talker], \recBuf, ~tatBufs.rec[\recTalkers].bufnum]),
            \sticker1 -> Synth(\bufSticker, [\bufnum, streams[\talkers].next.bufnum, \rate, 0.92, \out, outs[\sticker1]]),
            \sticker2 -> Synth(\bufSticker, [\bufnum, streams[\talkers].next.bufnum, \rate, 0.6, \amp, 0.8, \out, outs[\sticker2]]),
            \engine -> Synth([\talkyVosc, \chopTalk].choose, [\rootbuf, ~tatBufs.vosc.choose.at(0).bufnum, \recBuf, ~tatBufs.rec[\recEngines].bufnum, \out, outs[\engine]]),
            \wavesource -> Synth(\talkySquid, [\recBuf, ~tatBufs.rec[\recChipper].bufnum, \shapeBuf, ~tatBufs.distort[1].bufnum]),
            \wavesourceName -> \talkySquid,
            \sonk -> Synth(\saddy, [\bufnum, streams[\sonks].next.bufnum, \gate, 1, \spgate, 1, \rate, 0.6, \spread, 0.8, \amp, 8, \out, outs[\saddy]])
        ];

        // re-cue bombas and ludes
        ~tatBufs.bombas.do({|e, c|
            e.cueSoundFile(e.path);
        });
        ~tatBufs.ludes.do({|e, c|
            e.cueSoundFile(e.path);
        });

        // load the foire, mouths, and chipper modules
        (~docDir ++ "/modules/foire.scd").loadPaths();
        // (~docDir ++ "/modules/mouths.scd").loadPaths(); // mouths are too unstable
        (~docDir ++ "/modules/chipper.scd").loadPaths();

        // foire is a system that unleashes wavesets
        ~foire.out = outs[\foire];
        // customize some things
        ~foire.sourceProb = 0.8;
        ~foire.getWavesetBuf = {|self|
            var buf;
            (self.foiring.size.even).if({
                buf = ~tatBufs.rec[\waveset1];
            }, {
                buf = ~tatBufs.rec[\waveset2];
            });
            buf;
        };
        ~foire.copySourceBuf = {|self|
            (self.sourceProb.coin).if({
                ~tatBufs.rec[\recChipper].copyData(self.buf);
                self.sourceProb = (self.sourceProb * 0.925).max(0.4);
            }, {
                ~tatBufs.rec[\recTalkers].copyData(self.buf);
                self.sourceProb = (self.sourceProb * 1.1).min(0.9);
            });
        };
        ~foire.getDecay = {|self|
            betarand(0.06,1.3,0.2,1);
        };
        ~foire.synthName = \bitOBuf;
        ~foire.playSynth = {|self, args|
            Synth.grain(self.synthName, args ++ [\shapeBuf, ~tatBufs.distort.choose.bufnum]);
        };

        // mouth is a puffy character that complements foire
        // (when it doesn't emit horrid pops... hence, commented out)
        /*~mouths.out = outs[\mouth];
        ~mouths.playSynth = {|self, dur = 1|
            Synth(\mouth, self.genArgs(dur) ++ [\shapeBuf, ~tatBufs.distort.choose.bufnum]);
        };*/

        // chipper is a system for launching bursts of short samples
        ~chipper.out = outs[\chipper];
        ~chipper.resetPathStream(~tatBufs.chipPaths);
        ~chipper.threshold = rrand(100, 200);
        /*~chipper.bufSynthMono = \bufbuf1;
        ~chipper.bufSynthStereo = \bufbuf2;*/

        // method for playing interlude
        ~lude = Environment.new;
        ~lude.know = true;
        ~lude.out = outs[\lude];
        ~lude.bufStream = Pseq(~tatBufs.ludes.scramble, inf).asStream;
        ~lude.ludeing = false;
        ~lude.go = {|self|
            var b;
            b = self.bufStream.next;
            SoundFile.use(b.path, {|x|
                self.ludeing = true;
                // play the lude
                {
                    var d=DiskIn.ar(b.numChannels, b.bufnum) * -3.7.dbamp;
                    FreeSelfWhenDone.kr(d);
                    d
                }.play(s, self.out);
                // stop the main synths
                {
                    rrand(0, 3.0).wait;
                    synths[\engine].free;
                    synths[\sonk].set(\amp, 0, \spread, rrand(0.67, 0.87));
                    ~tatBufs.remakeVosc.value();
                    rrand(0, 8.0).wait;
                    // silence the inner wavesource to stop chips
                    synths[\wavesource].run(false);
                }.fork;
                // restart and reset things when the lude is done
                {
                    (x.duration * rrand(1, 1.02)).wait;
                    self.ludeing = false;
                    ~chipper.resetPathStream(~tatBufs.chipPaths);
                    synths[\engine] = Synth(\talkyVosc, [\rootbuf, ~tatBufs.vosc.choose.at(0).bufnum, \recBuf, ~tatBufs.rec[\recEngines].bufnum, \out, outs[\engine]]);
                    synths[\wavesource].run(true);
                    synths[\sonk].set(\bufnum, streams[\sonks].next.bufnum);
                    b.free;
                    holdIt = false;
                }.fork;
            });
        };

        // bombas are pretty simple, so we just have a function for them
        bomba = {
            var bufs = [streams[\bombas].next, streams[\bombas].next],
            // use the foire method for durations so they're proportional to each other
            durations = ~foire.generateDurations(4, 16, irritation * 1.9, irritation * 20);
            {
                var sig, t;
                t = EnvGen.kr(Env([0, 1, 1, 0], [1, durations.maxItem * rrand(1.2, 1.5), 0.067]), doneAction: 2);
                sig = Array.fill(2, {|c|
                    var v;
                    v=VDiskIn.ar(2, bufs[c], rrand(0.85, 1.0).ring1(EnvGen.kr(Env([rrand(1.5,2.5),0.0],[rrand(0.75, 1.25)],[rrand(-4,-1)]))), loop: 1) * rrand(0.9, 1.0);
                    (c.odd).if({
                        v = v.reverse;
                    });
                    v;
                }) * t;
                (~numChans > 2).if({
                    sig.flatten;
                }, {
                    Mix(sig);
                });
            }.play(s, outs[\bomba]);
            // return the full duration
            durations.maxItem;
        };

        // respond to "silences"
        o = OSCFunc({|msg|
            switch(msg[2],
                1000, {
                    // silences from "engine" synth
                    (holdIt.not.and(governor.coin)).if({
                        var dudeAmp = [0, 0.2, 0.667, 1.0, 1.5].wchoose([0.11, 0.15, 0.2, 0.5, 0.04]);
                        holdIt = true;
                        governor = (governor * 0.98).max(0.88);
                        { 0.5.wait; holdIt = false }.fork;
                        // change minor things
                        synths[\engine].set(\fmul, [1, 2, 4, 7].wchoose([0.45, 0.25, 0.15, 0.15]));
                        synths[\uncommon].set(\amp, dudeAmp);
                        synths[\sonk].set(\amp, (1 - dudeAmp).max(0) * 8);
                        // change sonk qualities depending on its volume
                        (0.5.coin && (dudeAmp < 1)).if({
                            synths[\sonk].set(\rate, [0.6, 0.5, 0.3, 0.85].wchoose([0.6, 0.2, 0.1, 0.1]), \spread, rrand(0.67, 0.87));
                        }, {
                            ((dudeAmp >= 1) && 0.4.coin).if({ { 1.wait; synths[\sonk].set(\bufnum, streams[\sonks].next.bufnum); }.fork });
                        });
                        // maybe spit out the recorded buffer or change the talkers
                        // foire if the irriation is high enough
                        (0.47.coin).if({
                            var waitit;
                            synths[\engine].run(false);
                            // a.run(false);
                            irritation = (irritation * rrand(1.05, 1.1)).min(0.4);
                            (0.7.coin).if({
                                waitit = rrand(1.0, 4.7);
                                Synth.grain(\spitter, [
                                    \out, outs[\spitter],
                                    \shapeBuf, ~tatBufs.distort.choose.bufnum,
                                    \buf, ~tatBufs.rec[[\recEngines, \recAll].wchoose([0.85, 0.15])].bufnum
                                ]);
                            }, {
                                (0.93.coin).if({
                                    synths[\sticker1].set(\bufnum, streams[\talkers].next.bufnum);
                                });
                                (0.93.coin).if({
                                    synths[\sticker2].set(\bufnum, streams[\talkers].next.bufnum);
                                });
                                waitit = rrand(1.1, 6.5);
                            });
                            // start back up and change some parameters
                            {
                                waitit.wait;
                                synths[\sticker1].set(\rate, rrand(0.85, 1.0));
                                synths[\sticker2].set(\rate, rrand(0.5, 0.84));
                                (0.5.coin && ~lude.ludeing.not).if({
                                    synths[\engine].free;
                                    synths[\engine] = Synth([\talkyVosc, \chopTalk].wchoose([0.6, 0.4]), [\rootbuf, ~tatBufs.vosc.choose.at(0).bufnum, \recBuf, ~tatBufs.rec[\recEngines].bufnum, \out, outs[\engine]]);
                                }, {
                                    (0.5.coin).if({
                                        synths[\engine].set(\rootbuf, ~tatBufs.vosc.choose.at(0).bufnum);
                                    });
                                    synths[\engine].run(true);
                                });
                            }.fork;
                        });
                        // if the time is right, foire away
                        (irritation.coin).if({
                            // do a lude if we've foired enough for now (see false block)
                            (~foire.numFoired < ~foire.threshold).if({
                                var waittime;
                                (~foire.numFoired == (~foire.threshold * (8/13)).round).if({
                                    waittime = bomba.value();
                                    {
                                        rrand(0.25, 1.0.min(waittime - 0.2)).wait;
                                        synths[\engine].run(false);
                                        // a.run(false);
                                        synths[\sonk].set(\gate, 0);
                                        (0.6.coin).if({
                                            synths[\sonk].set(\spgate, 0);
                                        });
                                    }.fork;
                                }, {
                                    // going to foire
                                    waittime = ~foire.go(4, 16, irritation * 1.9, irritation * 20);
                                    // maybe mouths too
                                    /*(0.25.coin).if({
                                        ~mouths.go(rrand(2, 4), waittime * 0.3, waittime * 0.9);
                                    });*/
                                    // stop others and start recording once the wavesets are ready
                                    {
                                        ~foire.wavesetCondition.wait;
                                        synths[\engine].run(false);
                                        synths[\sonk].set(\gate, 0);
                                        (0.6.coin).if({
                                            synths[\sonk].set(\spgate, 0);
                                        });
                                        synths[\record].set(\run, 1);
                                    }.fork;
                                });
                                // wait and then turn stuff back on
                                {
                                    waittime.wait;
                                    synths[\sticker1].set(\rate, rrand(0.7, 1.0));
                                    synths[\sticker2].set(\rate, rrand(0.38, 0.5));
                                    synths[\record].set(\run, 0);
                                    (~lude.ludeing.not).if({
                                        synths[\engine].run(true);
                                        synths[\sonk].set(\gate, 1, \spgate, 1, \spread, rrand(0.67, 0.87));
                                    });
                                    // maybe change the wavesource
                                    (0.3.coin).if({
                                        var newSynth = [\talkySquid, \offOnSite].choose;
                                        (newSynth != synths[\wavesourceName]).if({
                                            synths[\wavesource].free;
                                            synths[\wavesource] = Synth(newSynth, [\recBuf, ~tatBufs.rec[\recChipper].bufnum, \shapeBuf, ~tatBufs.distort[1].bufnum]);
                                        });
                                    });
                                }.fork;
                                irritation = (irritation * rrand(0.9, 0.98)).max(0.09);
                                ~foire.incrementNumFoired();
                            }, {
                                ~lude.go();
                                ~foire.resetCounts();
                                ~chipper.resetThresholds();
                                irritation = (irritation * 0.6).max(0.09);
                            });
                            synths[\engine].set(\rmul, [1, 0.5, 2].wchoose([0.85, 0.075, 0.075]));
                        });
                    }, {
                        governor = (governor * 1.02).min(1);
                    });
                },
                1001, {
                    // silences from "wavesource" synth
                    synths[\wavesource].set(\grain,[1,{ rrand(0.125,0.6) }].wchoose([0.9,0.1]).value,\mrate,rrand(1.5, 2.7));
                    (0.18.coin).if({
                        synths[\sticker1].set(\posGate, 1, \repRate, exprand(3.0, 15.0));
                        { rrand(0.7, 6).wait; synths[\sticker1].set(\posGate, 0, \repRate, 0) }.fork;
                    });
                    (0.13.coin).if({
                        synths[\sticker2].set(\posGate, 1, \repRate, exprand(3.0, 15.0));
                        { rrand(0.7, 6).wait; synths[\sticker2].set(\posGate, 0, \repRate, 0) }.fork;
                    });
                    ~chipper.increment();
                },
                1003, {
                    // free some chip bufs that we hope are no longer playing
                    ~chipper.cleanUp(msg[3]);
                }
  /*              2000, {
                    synths[\engine].free;
                    synths[\engine] = Synth([\talkyVosc, \chopTalk].choose, [\rootbuf, ~tatBufs.vosc.choose.at(0).bufnum, \recBuf, ~tatBufs.rec[\recEngines].bufnum]);
                    "Fix it".postln;
                }, */
            );
        }, '/tr', s.addr);
    };

    no = {
        CmdPeriod.run;
    };

    w = Window.new('These are They', Rect(300, 600, 410, 70));
    butt = Button(w, Rect(180, 20, 50, 30))
    .states_([
        ['Start', Color.black, Color.green],
        ['Stop', Color.white, Color.red]
    ])
    .action_({|v|
        (v.value == 1).if({
            { go.value(); }.defer;
        }, {
            { no.value(); }.defer;
        });
    });
    w.front;
    w.onClose_({ no.value() });
});
)