import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"

const time = Variable("").poll(1000, "date")

export default function Bar(gdkmonitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

    return (
        <window
            className="Bar"
            gdkmonitor={gdkmonitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={TOP | LEFT | RIGHT}
            application={App}
            child={
                <centerbox>
                    <button
                        onClicked="echo hello"
                        halign={Gtk.Align.CENTER}
                        child={<label label="Welcome to AGS!" />}
                    />
                    <box />
                    <button
                        onClicked={() => print("hello")}
                        halign={Gtk.Align.CENTER}
                        child={<label label={time()} />}
                    />
                </centerbox>
            }
        />
    )
}
