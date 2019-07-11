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
    ~generateDurations = {|self, minnum = 4, maxnum = 16, mindur = 1, maxdur = 30|
        Array.rand(rrand(minnum, maxnum), mindur, maxdur);
    };
    ~getEventDurations = {|self, durations|
        var ds, waitdur;
        ds = durations.at(durations.order({|a, b| b < a }));
		waitdur = ds.foldAt(rrand(0, 2).round) + exprand(0.01, 3);
        [ds[0], waitdur];
    };
    ~getModStartsAndEnds = {|self, minsize = 1, maxsize = 10, ws|
        var msf, mef;
        (self.didUnison < 1).if({
            msf = { rrand(0, ws.fracXings.size - maxsize - 1) };
            mef = {|st| st + [rrand(minsize, maxsize - 2), rrand(minsize + 3, maxsize)].wchoose([0.7, 0.3]) };
        }, {
            msf = rrand(0, ws.fracXings.size - maxsize);
            mef = msf + [rrand(minsize, maxsize - 2), rrand(minsize + 3, maxsize)].wchoose([0.7, 0.3]);
        });
        [msf, mef];
    };
    ~getWaveformStartsAndEnds = {|self, num = 4, minsize = 3, maxsize = 10, ws|
        var starts, ends;
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
		var durations, totaldur, outdur, maxCalculatedDur = 0, mrf, wf, amp, hmul, x, z, c = Condition.new(false);
        self.foiring.add(1);
		((self.didUnison * 0.1 + 0.15).coin).if({
			mrf = { betarand(0.0004, 0.001, 0.2, 0.3) * [1, 0.5].wchoose([0.9, 0.1]) };
			wf = { [rrand(0, 0.333), rrand(0.1, 0.67)].wchoose([0.6, 0.4]) };
			amp = 1;
			hmul = [1, rrand(1.8, 3.0)].wchoose([0.86, 0.14]);
			self.didUnison = 0;
		}, {
			mrf = betarand(0.0004, 0.001, 0.2, 0.3) * [1, 0.5].wchoose([0.9, 0.1]);
			wf = 0;
			amp = 0.6;
			hmul = [rrand(1.8, 3.6), rrand(2.5, 4.2)].wchoose([0.9, 0.1]);
			self.didUnison = 1;
		});
		durations = self.generateDurations(minnum, max(maxnum * self.didUnison, maxnum * 0.5), mindur, maxdur) * hmul;
		#totaldur, outdur = self.getEventDurations(durations);
		{
			z = Buffer.alloc(s, 4 * s.sampleRate, 1);
			s.sync;
			self.copySourceBuf(z);
			z.loadToFloatArray(0,-1,{|fa|
				var sig=Signal.newFrom(fa);
				x=Wavesets.new(\foire ++ Process.elapsedTime, sig, z.sampleRate);
				c.test=true;
				c.signal;
			});
			c.wait;
			{
				var asf, aef, fsf, fef;
				// rrand(0.0, 1).wait;
				#asf, aef = self.getModStartsAndEnds(6, 20, x);
				#fsf, fef = self.getModStartsAndEnds(6, 20, x);
				durations.do({|e, c|
					var amodstart = asf.value(),
					amodend = aef.value(amodstart),
					fmodstart = fsf.value(),
					fmodend = fef.value(fmodstart),
					modrate = amodend - amodstart * 0.5 * mrf.value(),
					moddur,
					starts,
					ends,
					rates,
					dur,
					pause = wf.value,
					decay = self.getDecay();
					#starts, ends = self.getWaveformStartsAndEnds(4, 3, 10, x);
					moddur = x.fracXings[amodend] - x.fracXings[amodstart] / z.sampleRate / modrate;
					dur = max((e / moddur).round * moddur, moddur);
					(dur > 0).if({
						maxCalculatedDur = max(maxCalculatedDur, dur + decay);
						rates = Array.fill(4, { betarand(0.005, 1.8, 0.2, 1.0) * [-1, 1].choose([0.4, 0.6]) });
						self.playSynth([
							\out, self.out,
							\buf, z,
							\arf, modrate * [-1, 1].choose,
							\astart, x.fracXings[amodstart],
							\aend, x.fracXings[amodend],
							\fstart, x.fracXings[fmodstart],
							\fend, x.fracXings[fmodend],
							\starts, starts,
							\ends, ends,
							\amp, amp,
							\dur, dur,
							\dec, decay,
							\rates, rates
						]);
					});
					pause.wait;
				});
				(maxCalculatedDur + durations.size).wait;
				self.foiring.pop;
				z.free;
			}.fork;
		}.fork;
        // return the waiting time
        outdur;
    };
});
~foire.know = true;