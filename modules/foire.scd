~foire = Environment.make({
    ~threshold = rrand(10, 13);
    ~foiring = List.new;
    ~didUnison = 0;
    ~numFoired = 0;
    ~out = 0;
    ~waveset = nil;
    ~buf = nil;
    ~synthName = nil;
    ~wavesetCondition = Condition.new(false);
    ~incrementNumFoired = {|self|
        self.numFoired = self.numFoired + 1;
    };
    ~resetThreshold = {|self, min=11, max=13|
        self.threshold = rrand(min, max);
    };
    ~resetCounts = {|self, min=11, max=13|
        self.numFoired = 0;
        self.resetThreshold(min, max);
    };
    ~getWavesetBuf = {|self|
        self.buf;
    };
    ~copySourceBuf = {|self, srcBuf|
        srcBuf.copyData(self.buf);
    };
    ~loadWavesets = {|self|
        var c = self.wavesetCondition;
        c.test=false;
        c.signal;
        Wavesets.clear;
        self.buf = self.getWavesetBuf.value;
        self.copySourceBuf();
        // self.buf.normalize;
        self.buf.loadToFloatArray(0,-1,{|fa|
            var sig;
            sig=Signal.newFrom(fa);
            self.waveset=Wavesets.new(\buff,sig,self.buf.sampleRate);
            c.test=true;
            c.signal;
        });
    };
    ~generateDurations = {|self, minnum = 4, maxnum = 16, mindur = 1, maxdur = 30|
        Array.rand(rrand(minnum, maxnum), mindur, maxdur);
    };
    ~getEventDurations = {|self, durations|
        var ds, waitdur;
        ds = durations.at(durations.order({|a, b| b < a }));
        waitdur = ds[rrand(0, 3).round] + exprand(0.01, 3);
        [ds[0], waitdur];
    };
    ~getModStartsAndEnds = {|self, minsize = 1, maxsize = 10|
        var msf, mef, ws = self.waveset;
        (self.didUnison < 1).if({
            msf = { rrand(0, ws.fracXings.size - maxsize - 1) };
            mef = {|st| st + [rrand(minsize, maxsize - 2), rrand(minsize + 3, maxsize)].wchoose([0.7, 0.3]) };
        }, {
            msf = rrand(0, ws.fracXings.size - 10);
            mef = msf + [rrand(minsize, maxsize - 2), rrand(minsize + 3, maxsize)].wchoose([0.7, 0.3]);
        });
        [msf, mef];
    };
    ~getWaveformStartsAndEnds = {|self, num = 4, minsize = 3, maxsize = 10|
        var starts, ends, ws = self.waveset;
        starts = Array.fill(num, { rrand(0, ws.fracXings.size - maxsize - 1) });
        ends = Array.fill(num, {|i| starts[i] + rrand(minsize, maxsize) });
        starts = Array.fill(num, {|i| ws.fracXings[starts[i]] });
        ends = Array.fill(num, {|i| ws.fracXings[ends[i]] });
        [starts, ends];
    };
    ~getDecay = {|self|
        0.01;
    };
    ~playSynth = {|self, args|
        Synth(self.synthName, args);
    };
    ~go = {|self, minnum = 4, maxnum = 16, mindur = 1, maxdur = 30|
        var durations, totaldur, outdur, mrf, wf, amp, hmul;
        self.foiring.add(1);
        self.loadWavesets();
        ((self.didUnison * 0.1 + 0.367).coin).if({
            mrf = { betarand(0.0004, 0.006, 0.1, 0.3) * [1, 0.5].wchoose([0.9, 0.1]) };
            wf = { [0, rrand(0.1, 0.67)].wchoose([0.6, 0.4]) };
            amp = 1;
            hmul = [1, rrand(1.8, 3.0)].wchoose([0.86, 0.14]);
            self.didUnison = 0;
        }, {
            mrf = betarand(0.0004, 0.0047, 0.1, 0.3) * [1, 0.5].wchoose([0.9, 0.1]);
            wf = 0;
            amp = 0.6;
            hmul = [rrand(1.8, 3.6), rrand(3.6, 5.0)].wchoose([0.9, 0.1]);
            self.didUnison = 1;
        });
        durations = self.generateDurations(minnum, maxnum, mindur, maxdur) * hmul;
        #totaldur, outdur = self.getEventDurations(durations);
        {
            totaldur.wait;
            self.foiring.pop;
        }.fork;
        {
            var msf, mef, x;
            self.wavesetCondition.wait;
            x = self.waveset;
            // rrand(0.0, 1).wait;
            #msf, mef = self.getModStartsAndEnds(1, 10);
            durations.do({|e, c|
                var modstart = msf.value(),
                modend = mef.value(modstart),
                modrate = mrf.value(),
                moddur,
                starts,
                ends,
                dur;
                #starts, ends = self.getWaveformStartsAndEnds(4, 3, 10);
                moddur = modend - modstart / self.buf.sampleRate / modrate;
                dur = (e / moddur).round * moddur;
                self.playSynth([
                    \out, self.out,
                    \buf, self.buf,
                    \modfreq, modrate * [-1, 1].choose,
                    \modstart, x.fracXings[modstart],
                    \modend, x.fracXings[modend],
                    \starts, starts,
                    \ends, ends,
                    \amp, amp,
                    \dur, dur,
                    \dec, self.getDecay(),
                    \rates, Array.fill(4, { betarand(0.005, 1.8, 0.2, 1.0) * [-1, 1].choose([0.4, 0.6]) })
                ]);
                wf.value.wait;
            });
        }.fork;
        // return the waiting time
        outdur;
    };
});
~foire.know = true;