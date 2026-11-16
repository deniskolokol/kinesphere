(
var samplesDir;
var dictObjSeq, msetObjSeq; // Markov chains creating sequences and obtaining objects' birthtime
var woc = {
    // WOC = WObbly Center.
    (~worldSize / 2) + (~worldSize * 0.01).rand
};

//GLOBAL
~sequence[\title] = "Orbitalna";

// Set constant depth.
~depth = 8;

// INITIAL
//
// Sequence rules (Markov set).
dictObjSeq = (
    // [number of repeats] (to choose from) -> [timelapse] (current moment and age)
    0: [(4..12), (1..6)], // short
    1: [[1, 3, 5, 7, 9], ({rrand(5, 40)} ! 10)], // average
    2: [[1, 2], ({rrand(30, 120)} ! 10)] // long (repeat)
);
msetObjSeq = MarkovSetN([], 2);
dictObjSeq.keysValuesDo{|k, v| msetObjSeq[k] = v[1]};
[
    FloatArray[0, 3, 7, 10], // scales[0] is the main scale
    FloatArray[0, 1, 3, 7, 8], // the rest are specific to sequence's parts
    FloatArray[0, 2],
    FloatArray[0, 3],
    FloatArray[1, 3],
].do { |c, i|
    ~sequence.scales.add(Buffer.sendCollection(~scsynth, c));
};

~sequence.events = (
    0: [
        (
            message: \action,  params: [\remove, \all],
            info: "Remove all before start\n Apply initial settings"
        ),
        (
            message: \physics,
            params: [
                \gravX, \default,
                \gravY, \default,
                \gravZ, \default,
                \drag, 0,
                \repulsion, 10,
                \maxVel, 150,
                \starMass, \default,
                \particleSystem, \default,
                \springRestLen, 3,
                \springStrength, 0.5,
                \springDamp, 2,
                \mutualAttraction, \default,
            ]
        ),
    ],
    5: [
        (
            wait: 120,
            info: "INTRO, no objects, only .kr buses",
            message: \g_new,
            id: \intro_bundle,
            params: [ // Keywords \next_node_id & \group_id are to be substituted by real IDs.
                ["/s_new", "humm__" ++ ~spatial.(), \next_node_id, 0, \group_id, // add synth to new group's head
                    \momentum, 0.5,
                    \attack, 40,
                    \bufnum, ~sequence.scales[4].bufnum,
                    \depth, ~depth,
                    \out, ~outbus
                ],
                ["/s_new", \klfno1, \next_node_id, 0, \group_id, \lfo, 0.2, \mul, 1pi, \out, 0],
                ["/n_map", \group_id, \azimuth, 0],
                ["/s_new", \kstepno, \next_node_id, 0, \group_id, \lfo, 0.08, \mul, 0.3, \add, 0.7, \out, 1],
                ["/n_map", \group_id, \distance, 1],
                ["/s_new", \klfno1, \next_node_id, 0, \group_id, \lfo, 0.1, \mul, 0.25, \add, 0.5, \out, 2],
                ["/n_map", \group_id, \momentum, 2],
                ["/s_new", \klfno1, \next_node_id, 0, \group_id, \lfo, 0.01, \mul, 0.1, \add, 0.1, \out, 3],
                ["/n_map", \group_id, \az, 3]
            ]
        )
    ],
    7: [
        (
            info: "INTRO: particleSystem",
            message: \physics, params: [\particleSystem, 1, \maxVel, 2]
        ),
        (
            info: "Silent object",
            message: \particle,
            synth: (name: "silent"),
            particle: (mass: 1, x: 470, y: 300, z: 250)
        ),
        (
            message: \task, name: \randomParticles, act: 1
        ),
    ],
    10: [
        (
            info: "Persistent floating <buzz>",
            message: \particle,
            synth: (
                name: "buzz",
                node: 1100,
                params: [
                    \attack, 20,
                    \release, 20,
                    \ca: 2,
                    \amp, 0.6,
                    \freq, 440,
                ]
            ),
            particle: (
                age: inf,
                mass: 1,
                x: woc.(), y: woc.(), z: woc.())
        ),
        (
            info: "TASK: `startLoop`",
            message: \task, name: \startLoop, act: 1
        ),
    ],
    20: [
        (
            info: "TASK: `magma`",
            message: \task, name: \magma, act: 1
        ),
    ],
    25: [
        (
            info: "switch OFF particles & tasks",
            message: \physics, params: [particleSystem: 0]
        ),
        (
            message: \task, name: \startLoop, act: 0
        ),
        (
            message: \task, name: \magma, act: 0
        ),

    ],
    30: [
        (
            info: "Physics environment change, 2 heavy <moog>",
            message: \physics,
            params: [\drag, 0.5, \repulsion, 10, \maxVel, 150]
        ),
        // Start 2 heavy <moog> w/default cutoff and long attack
        (
            info: "2 heavy <moog>",
            message: \particle,
            synth: (
                name: "moog",
                params: [\bufnum, ~sequence.scales[0].bufnum, \attack, 2 + 1.0.rand2, \release, 5, \threshold, 0.5]
            ),
            particle: (mass: 1, spring: 1, source: \r_hand)
        ),
        (
            message: \particle,
            synth: (
                name: "moog",
                params: [\bufnum, ~sequence.scales[0].bufnum, \attack, 2 + 1.0.rand2, \release, 5, \threshold, 0.5]
            ),
            particle: (mass: 1, spring: 1, source: \l_hand)
        ),
    ],
    99: [
        (
            info: "FIN: Remove all",
            message: \action,  params: [\remove, \all]
        )
    ]
);

// Tasks dictionary.
//
~sequence.tasks = (
    startLoop: Task({
        var age = 20.2;
        loop {
            ~sendParticle.(
                particle: (mass: 1, spring: 0, age: age, x: woc.(), y: woc.(), z: woc.()),
                synth: (name: "pole",
                    params: [\attack, rrand(1.0, 2.0), \ca, 2, \release, age, \amp, 0.5, \freq, "g 2".notemidi.midicps]
                )
            );
            ~sendParticle.(
                particle: (mass: 1, spring: 0, age: age, x: woc.(), y: woc.(), z: woc.()),
                synth: (name: "pole", params:
                    [\attack, rrand(2.0, 3.0), \ca, 2, \release, age, \amp, 0.5, \freq, "a 2".notemidi.midicps]
                )
            );
            ~sendParticle.(
                particle: (mass: 1, spring: 0, age: age, x: woc.(), y: woc.(), z: woc.()),
                synth: (name: "bass",
                    params: [\attack, 0.1, \ca, 2, \release, age, \amp, 0.7, \freq, "f 3".notemidi.midicps]
                )
            );
            age.wait;
        }
    }),
    magma: Task({
        var age;
        loop {
            #x, y, z = ~worldSize * ({ rrand(0.45, 0.55) } ! 3);
            age = 10;
            ~sendParticle.(
                particle: (mass: 1, age: age * rrand(0.85, 1), x: x, y: y, z: z),
                synth: (
                    name: "moog",
                    params:[\cutoff, -1, \attack, 0.2, \release, rrand(age*0.2, age*0.5)]
                )
            );
            ~sendParticle.(
                particle: (mass: 1, age: age * rrand(0.85, 1), x: x, y: y, z: z),
                synth: (
                    name: "silent",
                )
            );
            age.wait;
        }
    }),
)
)