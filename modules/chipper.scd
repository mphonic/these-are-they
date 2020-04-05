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
        self.threshold = [rrand(48,65), rrand(81, 110)].wchoose([0.94, 0.06]);
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
            var p, syn;
            (self.loadChip.not).if({
                p = self.pathStream.next;
            }, {
                p = self.lastChip;
            });
            (p != self.lastChip).if({
                {
                    s.sync;
                    self.loadChip = true;
                    Buffer.read(s, p, action: {|b|
                        cb.add(b);
                        self.loadChip = false;
                        self.lastChip = p;
                        (b.numChannels == 2).if({ syn = self.bufSynthStereo.value }, { syn = self.bufSynthMono.value });
                        self.playSynth(
                            syn,
                            [
                                \out, self.out,
                                \buf, b,
                                \rate, betarand(0.1, 1.9, 0.8, 1.2) * [1, -1].wchoose([0.75, 0.25]),
                                \at, rrand(0.067, 3) * tmul,
                                \dur, rrand(1, 8.0) * tmul,
                                \dec, rrand(0.067, 1) * tmul,
                                \panPos, rrand(-1.0, 1.0),
                                \panAmt, 0.4.rand,
                                \panModSpeed, exprand(0.1, 1.0),
                                \pos, rrand(0.0, 1.0),
                                \amp, rrand(0.3,0.7).squared
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
		var targetBuf = self.chipBufs.detect({|e| bufnum == e.bufnum });
		(targetBuf.notNil).if({
			(self.spentChips.indexOf(targetBuf.path).isNil).if({
				self.spentChips.add(targetBuf.path);
			});
		});
        (self.spentChips.size > 3).if({
			var lastIndex = self.spentChips.lastIndex - 1;
			self.chipBufs.copyRange(0, lastIndex).do({|e| e.free });
			self.chipBufs = self.chipBufs.copyRange(lastIndex + 1, self.chipBufs.lastIndex);
            self.spentChips = List[self.spentChips.pop];
        });
    };
});
~chipper.know = true;
~chipper.resetThresholds();