~chipper = Environment.make({
    ~pathStream = nil;
    ~resetPathStream = {|self, pathArray|
        self.pathStream = Pseq(pathArray.scramble.sputter(0.6667), inf).asStream;
    };
    ~loadChip = false;
    ~lastChip = nil;
    ~chipBufs = List.new;
    ~spentChips = List.new;
    ~out = 0;
    ~requests = 0;
    ~threshold = 10;
    ~resetThresholds = {|self|
        self.threshold = [rrand(47,70), rrand(297, 520)].wchoose([0.98, 0.02]);
        self.requests = 0;
    };
    ~increment = {|self|
        self.requests = self.requests + 1;
        (self.requests > self.threshold).if({
            self.go();
            self.resetThresholds();
        });
    };
    ~bufSynthMono = \bufbuf1;
    ~bufSynthStereo = \bufbuf2;
    ~playSynth = {|self, synthName, args|
        Synth.grain(synthName, args);
    };
    ~go = {|self|
        var tmul = [1, rrand(1.25, 2.0)].wchoose([0.9, 0.1]),
        cb = self.chipBufs;
        exprand(1, 7).round.do({
            var buf, syn;
            (self.loadChip.not).if({
                buf = self.pathStream.next;
            }, {
                buf = self.lastChip;
            });
            (buf != self.lastChip).if({
                {
                    s.sync;
                    self.loadChip = true;
                    Buffer.read(s, buf, action: {|b|
                        cb.add(b);
                        self.loadChip = false;
                        self.lastChip = buf;
                        (b.numChannels == 2).if({ syn = self.bufSynthStereo.value }, { syn = self.bufSynthMono.value });
                        self.playSynth(
                            syn,
                            [
                                \out, self.out,
                                \buf, b,
                                \rate, rrand(0.1, 1.9) * [1, -1].wchoose([0.75, 0.25]),
                                \at, rrand(0.067, 3) * tmul,
                                \dur, rrand(1, 8.0) * tmul,
                                \dec, rrand(0.067, 1) * tmul,
                                \panPos, rrand(-1.0, 1.0),
                                \panAmt, 0.4.rand,
                                \panModSpeed, exprand(0.1, 1.0),
                                \pos, rrand(0.0, 1.0),
                                \amp, rrand(0.5,0.9).squared
                            ]
                        );
                    });
                }.fork;
                // self.chipBufs.postln;
            }, {
                (cb.at(cb.size - 1).numChannels == 2).if({ syn = \bufbuf2 }, { syn = \bufbuf1 });
                self.playSynth(
                    syn,
                    [
                        \out, self.out,
                        \buf, cb.at(cb.size - 1),
                        \rate, rrand(0.1, 1.9) * [1, -1].choose,
                        \at, rrand(0.067, 3) * tmul,
                        \rel, rrand(2, 8.0) * tmul,
                        \panPos, rrand(-1.0, 1.0),
                        \panAmt, 0.1.rand,
                        \panModSpeed, exprand(0.1, 1.0),
                        \pos, rrand(0.0, 1.0),
                        \amp, rrand(0.5,0.9).squared
                    ]
                );
            });
        });
    };
    ~cleanUp = {|self, bufnum|
        self.chipBufs.do({|e, c|
            (bufnum == e.bufnum).if({
                ((e.path != self.lastChip).and(self.spentChips.indexOf(c).isNil)).if({
                    self.spentChips.add(c);
                });
            });
        });
        (self.spentChips.size > 3).if({
            self.spentChips.do({|e, c|
                (c < (self.spentChips.size - 1)).if({
                    self.chipBufs.at(c).free;
                    self.chipBufs.removeAt(c);
                });
            });
            self.spentChips = List[self.spentChips[self.spentChips.size - 1]];
        });
    };
});
~chipper.know = true;
~chipper.resetThresholds();