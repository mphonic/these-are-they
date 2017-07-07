~mouths = Environment.make({
    ~out = 0;
    ~genArgs = {|self, dur=1|
        var
        a = exprand(0.006667, 0.3),
        b,
        c = rrand(0.1, 0.4),
        d,
        f = [2200, 3305, 8192, 13305, 22000].choose,
        ar, ad, fr, fd, amp, pan, out, set;

        (0.5.coin).if({
            b = a * exprand(0.5, 0.99);
            d = rrand(1.08, 1.9);
        }, {
            b = exprand(0.006667, 0.3);
            d = rrand(0.85, 1.9);
        });

        (a < b).if({
            var tmpa;
            tmpa = a;
            a = b;
            b = tmpa;
        });
        (d >= 1.0).if({
            ar = exprand(3.0, 7.0);
            ad = rrand(0.85, 0.95);
            fr = exprand(0.05, 0.7);
            fd = rrand(0.02, 0.5);
            amp = rrand(0.6, 0.9);
        }, {
            ar = exprand(2.0, 5.0);
            ad = rrand(0.15, 0.94);
            fr = [exprand(0.05, 0.3), exprand(0.5, 8.0)].wchoose([0.8, 0.2]);
            (fr > 3.0).if({
                fd = rrand(0.3, 0.6);
            }, {
                fd = rrand(0.02, 0.25);
            });
            (b / a > 0.9).if({
                fr = fr * 0.1;
            });
            amp = rrand(0.7, 0.93).squared;
        });

        set = [
            \f, f,
            \a, a,
            \b, b,
            \c, c,
            \d, d,
            \ar, ar,
            \ad, ad,
            \fr, fr,
            \fd, fd,
            \amp, amp,
            \dur, dur,
            \pan, rrand(-1.0, 1.0),
            \fade, rrand(1.0, 8.0),
            \out, self.out
        ];
        // set.postln;
/*        (makeOut).if({
            set = set ++ [\out, out, \shapeBuf, sb[buf].bufnum];
        });*/
        set;
    };
    ~playSynth = {|self, dur = 1|
        Synth(\mouth, self.genArgs(dur));
    };
    ~go = {|self, num = 2, mindur = 1, maxdur = 15|
        {
            num.do({
                self.playSynth(rrand(mindur, maxdur));
                rrand(0.05, 3.min(maxdur)).wait;
            });
        }.fork;
    }
});
~mouths.know = true;