(
var margin=10, gap=5;
var colorButton=Color.grey(0.3);
var colorPane=Color.grey(0.05);
var transparent=Color.grey(alpha:0.0);
var fontLabel = Font("Menlo", 12);
var fontSmall=Font("Menlo", 10);
var fontMedium=Font("Menlo", 11);
var fontColor=Color.gray(0.7);

// The World is a cube with measurements equal to the screen height.
var world = (
    width: Window.screenBounds.height,
    height: Window.screenBounds.height,
    depth: Window.screenBounds.height
);

// GUI elements available to all functions.
var win;
var meterView;

// Main holder for world parameters and their GUI elements.
var worldParams = (
    drag: (
        label: "drag",
        minval: 0.000,
        maxval: 0.500,
        step: 0.001,
        default: 0.001,
        midicc: 24,
    ),
    repulsion: (
        label: "repulsion",
        minval: 1,
        maxval: 100,
        step: 5,
        default: 100,
        midicc: 25,
    ),
    maxVel: (
        label: "max vel",
        minval: 0.5,
        maxval: 10,
        step: 0.1,
        default: 5,
    ),
    starMass: (
        label: "star mass",
        minval: 0.1,
        maxval: 5,
        step: 0.1,
        default: 1,
        midicc: 26,
    ),
    gravX: (
        label: "grav X",
        minval: -2.1,
        maxval: 2.0,
        default: 0,
        // midicc: 27,
    ),
    gravY: (
        label: "grav Y",
        minval: -2.1,
        maxval: 2.0,
        default: 0,
        // midicc: 28,
    ),
    gravZ: (
        label: "grav Z",
        minval: -2.1,
        maxval: 2.0,
        default: 0,
        // midicc: 29,
    ),
    // springs
    springRestLen: (
        label: "rest len",
        minval: 1,
        maxval: 15,
        step: 1,
        default: 2,
        midicc: 31,
    ),
    springStrength: (
        label: "strength",
        minval: 0.1,
        maxval: 2,
        default: 1,
        midicc: 32,
    ),
    springDamp: (
        label: "damp",
        minval: 0.1,
        maxval: 2,
        default: 2,
        midicc: 33,
    ),
    // particle system
    particleSystem: (
        label: "particl",
        default: false,
        midinote: 45,
        hint: "run particle system",
    ),
    partSigmoidRatio: (
        label: "sigmoid",
        minval: 0.3,
        maxval: 0.9,
        default: 0.7,
        midicc: 34,
        hint: "steepness of sigmoid function determiming probability of particle being born",
    ),
    partAgeThresh: (
        label: "part age",
        minval: 0.1,
        maxval: 2,
        default: 0.84,
        midicc: 36,
        hint: "maximum particle age in cycles (sec)",
    ),
    partInitAccel: (
        label: "part accel",
        minval: 0.5,
        maxval: 30,
        default: 5,
        hint: "particle initial acceleration",
    ),
    partDefaultMass: (
        label: "part mass",
        minval: 0.1,
        maxval: 1,
        default: 0.5,
    ),
    partFreq: (
        label: "part freq",
        minval: 0.02,
        maxval: 0.9,
        default: 0.8,
        midicc: 35,
        hint: "generate new particle \partFreq times per second",
    ),
    partSynth: (
        label: "part synth",
        default: "pulse",
    ),
	// skelSimul
    mX: (
        label: "skel mX",
        minval: 0.1,
        maxval: 2.0,
        default: 1,
        midicc: 34,
    ),
    mY: (
        label: "skel mY",
        minval: 0.1,
        maxval: 2.0,
        default: 1,
        midicc: 35,
    ),
    mZ: (
        label: "skel mZ",
        minval: 0.1,
        maxval: 2.0,
        default: 1,
        midicc: 36,
    ),
    oX: (
        label: "skel oX",
        minval: -1.0,
        maxval: 1.0,
        default: 0.0,
        midicc: 31,
    ),
    oY: (
        label: "skel oY",
        minval: -1.0,
        maxval: 1.0,
        default: 0.0,
        midicc: 32,
    ),
    oZ: (
        label: "skel oZ",
        minval: -1.0,
        maxval: 1.0,
        default: 0.0,
        midicc: 33,
    ),
    skelSimulSpeed: (
        label: "simul vel",
        minval: 0.001,
        maxval: 0.05,
        default: 0.002,
		warp: \exp,
        midicc: 20,
        hint: "speed of skeleton simulation",
    ),
    skelSimul: (
        label: "skel",
        default: false,
        midinote: 69,
    ),
    skelPause: (
        label: "||",
        default: false,
        midinote: 59,
    ),
    skelRev: (
        label: "<<",
        default: false,
        midinote: 56,
    ),
    skelForw: (
        label: ">>",
        default: true,
        midinote: 57,
    ),
    // misc
    mutualAttraction: (
        label: "mutual",
        default: true,
        midinote: 44,
    ),
    internalBuf: (
        label: "internal buf",
        default: false,
        hint: "granular synths use internal buffer instead of samples",
    ),
    draw: (
        label: "drawing mode",
        default: \calibration,
        hint: "drawing mode description",
    ),
	tick: (
        label: "tick",
        minval: 0.001,
        maxval: 2.0,
        default: 1,
		warp: \lin,
		midicc: 20, // ?
        hint: "physics simulation speed",
    ),
);

// Updates world[`parm`] with `val` (substitutes 'default' keyword if needed),
// sets a proper value to the GUI controlling given world param.
var updateWorldParm = { |parm, val|
    if (val == \default) {
        val = worldParams[parm][\default];
    };
    try { world[parm] = val };
    updateGuiElement.(parm, val);
    val
};

// Updates value of a GUI element.
// If `action` is true, .valueAction is performed otherwise .value.
var updateGuiElement = { |parm, val, action=false|
    if (worldParams[parm].keys.includes(\gui)) {
        if (action) {
            { worldParams[parm][\gui].valueAction_(val) }.defer
        } {
            { worldParams[parm][\gui].value_(val) }.defer
        }
    }
};

// Create a panel for the server meter
// Return both the panel (for GUI bounds calc) and the meter view.
var placeServerMeter = { |parent|
    var server = ~scsynth;
    var panel, meterView;

    if (server.isNil) { server = Server.default };

    panel = View(
        parent, (parent.bounds.width-margin)@(parent.bounds.height*0.14)
    )
    .background_(transparent);
    meterView = EntroServerMeterView(server, panel, 0@0, 210);

    [panel, meterView]
};

var placeControls = { |parent|
    var panel = View(
        parent, (parent.bounds.width-margin)@(parent.bounds.height*0.5)
    )
    .background_(transparent);

    // Create a vertical flow layout for the controls
    panel.decorator = FlowLayout(panel.bounds, margin@margin, gap@gap);

    [
        \drag, \repulsion, \starMass,
        \gravX, \gravY, \gravZ,

        \mX, \mY, \mZ,
        \oX, \oY, \oZ,
        // XXX - do we need those?
        //
        // \springRestLen, \springStrength, \springDamp,
        // \maxVel, \partInitAccel, \partFreq,
        // \partDefaultMass, \partAgeThresh,
        \skelSimulSpeed, \tick
    ].do { |key, n|
        worldParams[key][\gui] = EZSlider(
            panel,
            (panel.bounds.width - (margin * 2))@20,
            format("% ", worldParams[key][\label]),
            ~valAsApec.(worldParams[key]),
            { |ez|

                // TODO:
                // eventPool.append((
                //     message: \physics,
                //     params: [worldParams[key][\label], updateWorldParm.(key, ez.value)]
                // ));
            },
            layout: \horz,
            labelWidth: 70,
            numberWidth: 50
        )
        .font_(fontSmall);
        worldParams[key][\gui].numberView.canFocus = false;
        worldParams[key][\gui].sliderView.canFocus = false;
        worldParams[key][\gui].setColors(
                stringColor:fontColor,
                sliderBackground:Color.black,
                numBackground:Color.grey(alpha:0.5),
                numNormalColor:fontColor,
                background:transparent
            );

        // Make a gap after every 3rd slider
        if ((n+1) % 3 == 0) { View(panel, (panel.bounds.width-margin)@gap).background_(transparent) };
    };

    // Skeleton simulation toggle button.
    worldParams.skelSimul[\gui] = Button(panel, (panel.bounds.width*0.2)@30)
        .states_([
            [worldParams.skelSimul[\label], fontColor, colorButton],
            [worldParams.skelSimul[\label], colorButton, fontColor]
        ])
        .font_(fontMedium)
        .canFocus_(false)
        .value_(worldParams.skelSimul[\default])
        .action_({ |bt|

            // TODO:
            // if (bt.value.booleanValue) {
            //     if (skelData.isNil) {loadSkelData.()};
            //     skelSimul.start
            // } {
            //     skelSimul.stop
            // }
        });

    // Skeleton simulation direction (forward or reverse) could
    // be realized with only one control (Rev={true, false}), but
    // two are used here for natural interaction with GUI and MIDI.
    [\skelRev, \skelForw].do { |param|
        worldParams[param][\gui] = Button(panel, (panel.bounds.width*0.1)@30)
        .states_([
            [worldParams[param][\label], fontColor, colorButton],
            [worldParams[param][\label], colorButton, fontColor]
        ])
        .font_(fontMedium)
        .canFocus_(false)
        .value_(world[param]);
    };
    worldParams[\skelRev][\gui].action_({ |bt|
        world[\skelRev] = bt.value.booleanValue;
        world[\skelForw] = bt.value.booleanValue.not;
        worldParams[\skelForw][\gui].value = bt.value.booleanValue.not;
    });
    worldParams[\skelForw][\gui].action_({ |bt|
        world.skelForw = bt.value.booleanValue;
        world.skelRev = bt.value.booleanValue.not;
        worldParams[\skelRev][\gui].value = bt.value.booleanValue.not;
    });

    // To keep simulated skeleton in the world, fake the pause: do not
    // pause task, but increase waiting time instead.
    worldParams.skelPause[\gui] = Button(panel, (panel.bounds.width*0.1)@30)
    .states_([
        [worldParams.skelPause[\label], fontColor, colorButton],
        [worldParams.skelPause[\label], colorButton, fontColor]
    ])
    .value_(worldParams.skelPause[\default])
    .action_({ |bt|
        if (bt.value.booleanValue) {
            // save current waiting time for later
            worldParams.skelSimulSpeed[\default] = world.skelSimulSpeed;
            world.skelSimulSpeed = 2
        } {
            world.skelSimulSpeed = worldParams.skelSimulSpeed[\default];
        }
    });

    panel;
};

// Main GUI creation function
var makeGUI = {
    var palette = QPalette.dark;
    var paneLeft, paneMain, paneRight;
    var panelMeterView, paneCtrls;
    var paneMainWidth = Window.screenBounds.height;
    var sidePaneWidth = ((Window.screenBounds.width - paneMainWidth) / 2) - margin;
    var paneHeight = Window.screenBounds.height - margin;

    win = Window.new(
        "Kinesphere",
        Rect(0, 0, Window.screenBounds.width, Window.screenBounds.height),
        resizable: false,
    );
    win.view.decorator = FlowLayout(win.view.bounds);
    win.view.decorator.gap=gap@gap;
    palette.setColor(Color.grey(0.1), \window);
    win.view.palette = palette;

    // Create main panels.
    //
    // Left panel for controls and display of the sequence's events.
    paneLeft = View(win, sidePaneWidth@paneHeight).background_(colorPane);
    paneLeft.decorator = FlowLayout(paneLeft.bounds, margin@margin, gap@gap);
    # panelMeterView, meterView = placeServerMeter.(paneLeft);
    paneCtrls = placeControls.(paneLeft);
    
    // Main panel for visualization.
    paneMain = View(win, paneMainWidth@paneHeight).background_(colorPane);

    // Right panel for additional controls and information.
    paneRight = View(win, sidePaneWidth@paneHeight).background_(colorPane);
    paneRight.decorator = FlowLayout(paneRight.bounds, margin@margin, gap@gap);

    // Shortcuts.
    win.view.keyDownAction = { |view, char, modifiers, unicode, keycode|
        [view, char, modifiers, unicode, keycode].postln;

        case
        { keycode == 3 } { // F
            if (modifiers == 262144) { // Ctrl + F
                if (win.bounds == Window.screenBounds) {
                    win.endFullScreen
                } {
                    win.fullScreen
                }
            }
        }
    };

    win.front;
};

// set default world params
worldParams.keysValuesDo { |k, v| world[k] = v[\default]};

makeGUI.();

CmdPeriod.doOnce({
    win.close;
});

)
