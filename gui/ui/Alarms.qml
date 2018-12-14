/*
 * Copyright (C) 2018
 *      Jean-Luc Barriere <jlbarriere68@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQml.Models 2.3
import NosonApp 1.0
import "../components"
import "../components/Delegates"
import "../components/Flickables"
import "../components/ListItemActions"
import "../components/Dialog"

MusicPage {
    id: alarmsPage
    objectName: "alarmsPage"
    pageTitle: qsTr("Alarm clock")
    pageFlickable: alarmList
    isListView: true
    listview: alarmList
    addVisible: true

    BlurredBackground {
        id: blurredBackground
        height: parent.height
    }

    RoomsModel {
        id: roomModel
        Component.onCompleted: {
            load(Sonos);
        }
    }

    Connections {
        target: Sonos
        onTopologyChanged: roomModel.load(Sonos)
    }

    DialogAlarm {
        id: dialogAlarm
        container: alarmsModel
        roomModel: roomModel

        onOpened: {
            alarmsModel.updatePending = true;
        }

        onClosed: {
            alarmsModel.updatePending = false;
        }
    }

    function getRoomById(id) {
        for (var i = 0; i < roomModel.count; ++i)
            if (roomModel.get(i).id === id)
                return roomModel.get(i);
        return { id: "none",  name: "" };
    }

    MultiSelectListView {
        id: alarmList
        anchors.fill: parent

        state: "default"

        model: DelegateModel {
            id: visualModel
            model: alarmsModel
            delegate: SelectMusicListItem {
                id: listItem
                listview: alarmList
                reorderable: false
                selectable: false
                highlighted: false

                // background
                Rectangle {
                    anchors.fill: parent
                    color: styleMusic.view.highlightedColor
                    opacity: (index % 2) === 1 ? 0.05 : 0.0
                }

                color: "transparent"
                description: qsTr("Alarm")

                signal editNew
                onEditNew: dialogAlarm.open(model, true, index)

                onClicked: {
                    alarmList.focusIndex = index;
                    dialogAlarm.open(model);
                }
                onActionPressed: {
                    model.enabled = !model.enabled;
                    if (!Sonos.updateAlarm(model.payload)) {
                        popInfo.open(qsTr("Action can't be performed"));
                        model.enabled = !model.enabled;
                    }
                }
                actionVisible: true
                actionIconSource: model.enabled ? "qrc:/images/media-record.svg" : "qrc:/images/media-preview-start.svg"
                onAction2Pressed: {
                    model.includeLinkedZones = !model.includeLinkedZones;
                    if (!Sonos.updateAlarm(model.payload)) {
                        popInfo.open(qsTr("Action can't be performed"));
                        model.includeLinkedZones = !model.includeLinkedZones;
                    }
                }
                action2Visible: true
                action2IconSource: model.includeLinkedZones ? "qrc:/images/share.svg" : "qrc:/images/location-idle.svg"
                menuVisible: true

                menuItems: [
                    MenuItem {
                        text: qsTr("Edit")
                        font.pointSize: units.fs("medium")
                        enabled: model.id.length > 0
                        onTriggered: {
                            alarmList.focusIndex = index;
                            dialogAlarm.open(model);
                        }
                    },
                    Remove {
                        enabled: true
                        visible: true
                        onTriggered: {
                            alarmList.focusIndex = index > 0 ? index - 1 : 0;
                            delayRemoveAlarm.start();
                            color = "red";
                        }
                    }
                ]

                contentHeight: units.gu(8)

                column: Column {
                    spacing: units.gu(1)

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

                    Label {
                        id: roomName
                        color: styleMusic.view.primaryColor
                        font.pointSize: units.fs("large")
                        text: getRoomById(model.roomId).name
                    }

                    Label {
                        id: recurrence
                        color: styleMusic.view.secondaryColor
                        font.pointSize: units.fs("small")
                        text: translateRecurrence(model.recurrence)
                    }

                    Label {
                        id: startTime
                        color: styleMusic.view.secondaryColor
                        font.pointSize: units.fs("large")
                        text: model.startLocalTime
                    }

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

                    function translateRecurrence(recurrence) {
                        var tr = "";
                        if (recurrence.indexOf("MON") >= 0)
                            tr = tr + qsTr("Mon") + ",";
                        if (recurrence.indexOf("TUE") >= 0)
                            tr = tr + qsTr("Tue") + ",";
                        if (recurrence.indexOf("WED") >= 0)
                            tr = tr + qsTr("Wed") + ",";
                        if (recurrence.indexOf("THU") >= 0)
                            tr = tr + qsTr("Thu") + ",";
                        if (recurrence.indexOf("FRI") >= 0)
                            tr = tr + qsTr("Fri") + ",";
                        if (recurrence.indexOf("SAT") >= 0)
                            tr = tr + qsTr("Sat") + ",";
                        if (recurrence.indexOf("SUN") >= 0)
                            tr = tr + qsTr("Sun") + ",";
                        if (tr.length > 0)
                            return tr.substr(0, tr.length - 1);
                        return tr;
                    }

                }

                Timer {
                    id: delayRemoveAlarm
                    interval: 100
                    onTriggered: {
                        if (!Sonos.destroyAlarm(model.id)) {
                            popInfo.open(qsTr("Action can't be performed"));
                            alarmList.focusIndex = index;
                            alarmsModel.asyncLoad();
                        }
                    }
                }
            }
        }

        property int focusIndex: 0

        Connections {
            target: alarmsModel
            onCountChanged: {
                if (alarmList.focusIndex < alarmsModel.count)
                    alarmList.positionViewAtIndex(alarmList.focusIndex, ListView.Center);
            }
        }
    }

    // Overlay to show when no alarms are on the device
    Loader {
        anchors.fill: parent
        active: alarmList.count === 0 && !infoLoadedIndex
        asynchronous: true
        source: "qrc:/components/AlarmsEmptyState.qml"
        visible: active
    }

    onAddClicked: {
        alarmsModel.updatePending = true; // lock model reset
        var r = alarmsModel.append();
        if (r >= 0) {
            while (alarmList.currentIndex < r)
                alarmList.incrementCurrentIndex();
            alarmList.focusIndex = r;
            alarmList.currentItem.editNew();
        } else {
            alarmsModel.updatePending = false; // relase model reset
            popInfo.open(qsTr("Action can't be performed"));
        }
    }
}