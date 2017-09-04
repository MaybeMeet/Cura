// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura
import "Menus"

Rectangle
{
    id: base;

    property int currentModeIndex;
    property bool hideSettings: PrintInformation.preSliced

    // Is there an output device for this printer?
    property bool printerConnected: Cura.MachineManager.printerOutputDevices.length != 0
    property bool printerAcceptsCommands: printerConnected && Cura.MachineManager.printerOutputDevices[0].acceptsCommands
    property var connectedPrinter: Cura.MachineManager.printerOutputDevices.length >= 1 ? Cura.MachineManager.printerOutputDevices[0] : null
    property int backendState: UM.Backend.state

    property bool monitoringPrint: false

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printDurationPerFeature: PrintInformation.printTimesPerFeature
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts

    color: UM.Theme.getColor("sidebar")
    UM.I18nCatalog { id: catalog; name:"cura"}

    Timer {
        id: tooltipDelayTimer
        interval: 500
        repeat: false
        property var item
        property string text

        onTriggered:
        {
            base.showTooltip(base, {x: 0, y: item.y}, text);
        }
    }

    function showTooltip(item, position, text)
    {
        tooltip.text = text;
        position = item.mapToItem(base, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip()
    {
        tooltip.hide();
    }

    function strPadLeft(string, pad, length) {
        return (new Array(length + 1).join(pad) + string).slice(-length);
    }

    function getPrettyTime(time)
    {
        var hours = Math.floor(time / 3600)
        time -= hours * 3600
        var minutes = Math.floor(time / 60);
        time -= minutes * 60
        var seconds = Math.floor(time);

        var finalTime = strPadLeft(hours, "0", 2) + ':' + strPadLeft(minutes,'0',2)+ ':' + strPadLeft(seconds,'0',2);
        return finalTime;
    }

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons;

        onWheel:
        {
            wheel.accepted = true;
        }
    }

    SidebarHeader {
        id: header
        width: parent.width
        visible: machineExtruderCount.properties.value > 1 || Cura.MachineManager.hasMaterials || Cura.MachineManager.hasVariants

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    Rectangle {
        id: headerSeparator
        width: parent.width
        visible: settingsModeSelection.visible && header.visible
        height: visible ? UM.Theme.getSize("sidebar_lining").height : 0
        color: UM.Theme.getColor("sidebar_lining")
        anchors.top: header.bottom
        anchors.topMargin: visible ? UM.Theme.getSize("sidebar_margin").height : 0
    }

    onCurrentModeIndexChanged:
    {
        UM.Preferences.setValue("cura/active_mode", currentModeIndex);
        if(modesListModel.count > base.currentModeIndex)
        {
            sidebarContents.push({ "item": modesListModel.get(base.currentModeIndex).item, "replace": true });
        }
    }

    Text {
        id: settingsModeLabel
        text: !hideSettings ? catalog.i18nc("@label:listbox", "Print Setup") : catalog.i18nc("@label:listbox","Print Setup disabled\nG-code files cannot be modified");
        anchors.left: parent.left
        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.top: headerSeparator.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        width: parent.width * 0.45 - 2 * UM.Theme.getSize("sidebar_margin").width
        font: UM.Theme.getFont("large")
        color: UM.Theme.getColor("text")
        visible: !monitoringPrint
        elide: Text.ElideRight
    }

    Rectangle {
        id: settingsModeSelection
        color: "transparent"
        width: parent.width * 0.55
        height: UM.Theme.getSize("sidebar_header_mode_toggle").height
        anchors.right: parent.right
        anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.top: headerSeparator.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        visible: !monitoringPrint && !hideSettings
        Component{
            id: wizardDelegate
            Button {
                height: settingsModeSelection.height
                anchors.left: parent.left
                anchors.leftMargin: model.index * (settingsModeSelection.width / 2)
                anchors.verticalCenter: parent.verticalCenter
                width: 0.5 * parent.width
                text: model.text
                exclusiveGroup: modeMenuGroup;
                checkable: true;
                checked: base.currentModeIndex == index
                onClicked: base.currentModeIndex = index

                onHoveredChanged: {
                    if (hovered)
                    {
                        tooltipDelayTimer.item = settingsModeSelection
                        tooltipDelayTimer.text = model.tooltipText
                        tooltipDelayTimer.start();
                    }
                    else
                    {
                        tooltipDelayTimer.stop();
                        base.hideTooltip();
                    }
                }

                style: ButtonStyle {
                    background: Rectangle {
                        border.width: UM.Theme.getSize("default_lining").width
                        border.color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_border") :
                                          control.hovered ? UM.Theme.getColor("action_button_hovered_border") :
                                          UM.Theme.getColor("action_button_border")
                        color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active") :
                                   control.hovered ? UM.Theme.getColor("action_button_hovered") :
                                   UM.Theme.getColor("action_button")
                        Behavior on color { ColorAnimation { duration: 50; } }
                        Label {
                            anchors.centerIn: parent
                            color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                       control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                       UM.Theme.getColor("action_button_text")
                            font: UM.Theme.getFont("default")
                            text: control.text;
                        }
                    }
                    label: Item { }
                }
            }
        }
        ExclusiveGroup { id: modeMenuGroup; }

        ListView
        {
            id: modesList
            property var index: 0
            model: modesListModel
            delegate: wizardDelegate
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width
        }
    }

    Item
    {
        id: globalProfileRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            top: settingsModeSelection.bottom
            topMargin: UM.Theme.getSize("sidebar_margin").height
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Text
        {
            id: globalProfileLabel
            text: catalog.i18nc("@label","Profile:");
            width: parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
            verticalAlignment: Text.AlignVCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        ToolButton
        {
            id: globalProfileSelection

            text: {
                var result = Cura.MachineManager.activeQualityName;
                if (Cura.MachineManager.activeQualityLayerHeight > 0) {
                    result += " <font color=\"" + UM.Theme.getColor("text_detail") + "\">";
                    result += " - ";
                    result += Cura.MachineManager.activeQualityLayerHeight + "mm";
                    result += "</font>";
                }
                return result;
            }
            enabled: !header.currentExtruderVisible || header.currentExtruderIndex > -1

            width: parent.width * 0.7 + UM.Theme.getSize("sidebar_margin").width
            height: UM.Theme.getSize("setting_control").height
            anchors.left: globalProfileLabel.right
            anchors.right: parent.right
            tooltip: Cura.MachineManager.activeQualityName
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;
            menu: ProfileMenu { }

            UM.SimpleButton
            {
                id: customisedSettings

                visible: Cura.MachineManager.hasUserSettings
                height: parent.height * 0.6
                width: parent.height * 0.6

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: UM.Theme.getSize("setting_preferences_button_margin").width - UM.Theme.getSize("sidebar_margin").width

                color: hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button");
                iconSource: UM.Theme.getIcon("star");

                onClicked:
                {
                    forceActiveFocus();
                    Cura.Actions.manageProfiles.trigger()
                }
                onEntered:
                {
                    var content = catalog.i18nc("@tooltip","Some setting/override values are different from the values stored in the profile.\n\nClick to open the profile manager.")
                    base.showTooltip(globalProfileRow, Qt.point(-UM.Theme.getSize("sidebar_margin").width, 0),  content)
                }
                onExited: base.hideTooltip()
            }
        }
    }

    StackView
    {
        id: sidebarContents

        anchors.bottom: footerSeparator.top
        anchors.top: globalProfileRow.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        anchors.left: base.left
        anchors.right: base.right
        visible: !monitoringPrint && !hideSettings

        delegate: StackViewDelegate
        {
            function transitionFinished(properties)
            {
                properties.exitItem.opacity = 1
            }

            pushTransition: StackViewTransition
            {
                PropertyAnimation
                {
                    target: enterItem
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 100
                }
                PropertyAnimation
                {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 100
                }
            }
        }
    }

    Loader
    {
        id: controlItem
        anchors.bottom: footerSeparator.top
        anchors.top: headerSeparator.bottom
        anchors.left: base.left
        anchors.right: base.right
        sourceComponent:
        {
            if(monitoringPrint && connectedPrinter != null)
            {
                if(connectedPrinter.controlItem != null)
                {
                    return connectedPrinter.controlItem
                }
            }
            return null
        }
    }

    Loader
    {
        anchors.bottom: footerSeparator.top
        anchors.top: headerSeparator.bottom
        anchors.left: base.left
        anchors.right: base.right
        source:
        {
            if(controlItem.sourceComponent == null)
            {
                if(monitoringPrint)
                {
                    return "PrintMonitor.qml"
                } else
                {
                    return "SidebarContents.qml"
                }
            }
            else
            {
                return ""
            }
        }
    }

    Rectangle
    {
        id: footerSeparator
        width: parent.width
        height: UM.Theme.getSize("sidebar_lining").height
        color: UM.Theme.getColor("sidebar_lining")
        anchors.bottom: printSpecs.top
        anchors.bottomMargin: UM.Theme.getSize("sidebar_margin").height * 2 + UM.Theme.getSize("progressbar").height + UM.Theme.getFont("default_bold").pixelSize
    }

    Rectangle
    {
        id: printSpecs
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.bottomMargin: UM.Theme.getSize("sidebar_margin").height
        height: childrenRect.height
        visible: !monitoringPrint

        UM.TooltipArea
        {
            id: timeSpecPerFeatureTooltipArea
            width: timeSpec.width
            height: timeSpec.height
            anchors.left: parent.left
            anchors.bottom: timeSpecDescription.top

            text: {
                var order = ["inset_0", "inset_x", "skin", "infill", "support_infill", "support_interface", "support", "travel", "retract", "none"];
                var visible_names = {
                    "inset_0": catalog.i18nc("@tooltip", "Outer Wall"),
                    "inset_x": catalog.i18nc("@tooltip", "Inner Walls"),
                    "skin": catalog.i18nc("@tooltip", "Skin"),
                    "infill": catalog.i18nc("@tooltip", "Infill"),
                    "support_infill": catalog.i18nc("@tooltip", "Support Infill"),
                    "support_interface": catalog.i18nc("@tooltip", "Support Interface"),
                    "support": catalog.i18nc("@tooltip", "Support"),
                    "travel": catalog.i18nc("@tooltip", "Travel"),
                    "retract": catalog.i18nc("@tooltip", "Retractions"),
                    "none": catalog.i18nc("@tooltip", "Other")
                };
                var result = "";
                for(var feature in order)
                {
                    feature = order[feature];
                    if(base.printDurationPerFeature[feature] && base.printDurationPerFeature[feature].totalSeconds > 0)
                    {
                        result += "<br/>" + visible_names[feature] + ": " + base.printDurationPerFeature[feature].getDisplayString(UM.DurationFormat.Short);
                    }
                }
                result = result.replace(/^\<br\/\>/, ""); // remove newline before first item
                return result;
            }

            Text
            {
                id: timeSpec
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                font: UM.Theme.getFont("large")
                color: UM.Theme.getColor("text_subtext")
                text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.Short)
            }
        }
        Text
        {
            id: timeSpecDescription
            anchors.left: parent.left
            anchors.bottom: lengthSpec.top
            font: UM.Theme.getFont("very_small")
            color: UM.Theme.getColor("text_subtext")
            text: catalog.i18nc("@description", "Print time")
        }
        Text
        {
            id: lengthSpec
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            font: UM.Theme.getFont("very_small")
            color: UM.Theme.getColor("text_subtext")
            text:
            {
                var lengths = [];
                var weights = [];
                var costs = [];
                var someCostsKnown = false;
                if(base.printMaterialLengths) {
                    for(var index = 0; index < base.printMaterialLengths.length; index++)
                    {
                        if(base.printMaterialLengths[index] > 0)
                        {
                            lengths.push(base.printMaterialLengths[index].toFixed(2));
                            weights.push(String(Math.floor(base.printMaterialWeights[index])));
                            var cost = base.printMaterialCosts[index] == undefined ? 0 : base.printMaterialCosts[index].toFixed(2);
                            costs.push(cost);
                            if(cost > 0)
                            {
                                someCostsKnown = true;
                            }
                        }
                    }
                }
                if(lengths.length == 0)
                {
                    lengths = ["0.00"];
                    weights = ["0"];
                    costs = ["0.00"];
                }
                if(someCostsKnown)
                {
                    return catalog.i18nc("@label", "%1m / ~ %2g / ~ %4 %3").arg(lengths.join(" + "))
                            .arg(weights.join(" + ")).arg(costs.join(" + ")).arg(UM.Preferences.getValue("cura/currency"));
                }
                else
                {
                    return catalog.i18nc("@label", "%1m / ~ %2g").arg(lengths.join(" + ")).arg(weights.join(" + "));
                }
            }
        }
    }

    // SaveButton and MonitorButton are actually the bottom footer panels.
    // "!monitoringPrint" currently means "show-settings-mode"
    SaveButton
    {
        id: saveButton
        implicitWidth: base.width
        anchors.top: footerSeparator.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        anchors.bottom: parent.bottom
        visible: !monitoringPrint
    }

    MonitorButton
    {
        id: monitorButton
        implicitWidth: base.width
        anchors.top: footerSeparator.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        anchors.bottom: parent.bottom
        visible: monitoringPrint
    }


    SidebarTooltip
    {
        id: tooltip;
    }

    // Setting mode: Recommended or Custom
    ListModel
    {
        id: modesListModel;
    }

    SidebarSimple
    {
        id: sidebarSimple;
        visible: false;

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    SidebarAdvanced
    {
        id: sidebarAdvanced;
        visible: false;

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    Component.onCompleted:
    {
        modesListModel.append({
            text: catalog.i18nc("@title:tab", "Recommended"),
            tooltipText: catalog.i18nc("@tooltip", "<b>Recommended Print Setup</b><br/><br/>Print with the recommended settings for the selected printer, material and quality."),
            item: sidebarSimple
        })
        modesListModel.append({
            text: catalog.i18nc("@title:tab", "Custom"),
            tooltipText: catalog.i18nc("@tooltip", "<b>Custom Print Setup</b><br/><br/>Print with finegrained control over every last bit of the slicing process."),
            item: sidebarAdvanced
        })
        sidebarContents.push({ "item": modesListModel.get(base.currentModeIndex).item, "immediate": true });

        var index = parseInt(UM.Preferences.getValue("cura/active_mode"))
        if(index)
        {
            currentModeIndex = index;
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: machineHeatedBed

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_heated_bed"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
