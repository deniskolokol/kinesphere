(
var margin=10, gap=5;
var colorButton=Color.grey(0.3);
var colorPane=Color.grey(0.05);
var transparent=Color.grey(alpha:0.0);
var fontLabel = Font("Menlo", 12);


// Main GUI creation function
~makeGUI = {
    var palette = QPalette.dark;
    var paneLeft, paneMain, paneRight;
    var paneMainWidth = Window.screenBounds.height;
    var sidePaneWidth = ((Window.screenBounds.width - paneMainWidth) / 2) - margin;
    var paneHeight = Window.screenBounds.height - margin;

    ~win = Window.new(
        "Kinesphere",
        Rect(0, 0, Window.screenBounds.width, Window.screenBounds.height),
        resizable: false,
    );
    ~win.view.decorator = FlowLayout(~win.view.bounds);
    ~win.view.decorator.gap=gap@gap;
    palette.setColor(Color.grey(0.1), \window);
    ~win.view.palette = palette;

    // Create main panels.
    //
    // Left panel for controls and display of the sequence's events.
    paneLeft = View(~win, sidePaneWidth@paneHeight).background_(colorPane);
    paneLeft.decorator = FlowLayout(paneLeft.bounds, margin@margin, gap@gap);

    // Main panel for visualization.
    paneMain = View(~win, paneMainWidth@paneHeight).background_(colorPane);

    // Right panel for additional controls and information.
    paneRight = View(~win, sidePaneWidth@paneHeight).background_(colorPane);
    paneRight.decorator = FlowLayout(paneRight.bounds, margin@margin, gap@gap);

    ~win.view.keyDownAction = { |view, char, modifiers, unicode, keycode|
        [view, char, modifiers, unicode, keycode].postln;

        case
        { keycode == 3 } { // F
            if (modifiers == 262144) { // Ctrl + F
                if (~win.bounds == Window.screenBounds) {
                    ~win.endFullScreen
                } {
                    ~win.fullScreen
                }
            }
        }
    };

    ~win.front;
};

CmdPeriod.doOnce({
    ~win.close;
});

~makeGUI.();
)
