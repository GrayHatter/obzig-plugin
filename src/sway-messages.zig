pub const Rect = struct {
    x: usize,
    y: usize,
    width: usize,
    height: usize,
};

pub const WindowChange = struct {
    change: []u8,
    container: Container,

    pub const Container = struct {
        id: usize,
        type: []u8,
        orientation: []u8,
        percent: f64,
        urgent: bool,
        marks: [][]u8,
        focused: bool,
        layout: []u8,
        border: []u8,
        current_border_width: usize,
        rect: Rect,
        deco_rect: Rect,
        window_rect: Rect,
        geometry: Rect,
        name: ?[]u8,
        window: ?usize,
        nodes: [][]u8,
        floating_nodes: [][]u8,
        focus: ?[][]u8,
        fullscreen_mode: usize,
        sticky: ?bool,
        pid: usize,
        app_id: ?[]u8,
        visible: ?bool,
        max_render_time: usize,
        shell: ?[]u8,
        inhibit_idle: bool,
        idle_inhibitors: struct {
            user: []u8,
            application: []u8,
        },

        // window_properties: struct {
        //     class: []u8,
        //     instance: []u8,
        //     transient_for: ?[]u8,
        // },
    };
};

pub const MsgKind = union(enum) {
    window: WindowChange,
};
