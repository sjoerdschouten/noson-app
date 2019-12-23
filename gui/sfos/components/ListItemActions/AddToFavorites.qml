/*
 * Copyright (C) 2019
 *      Jean-Luc Barriere <jlbarriere68@gmail.com>
 *      Adam Pigg <adam@piggz.co.uk>
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import NosonApp 1.0

MenuItem {
    property bool isFavorite: false
    property string description: ""
    property string art: ""
    property string iconSource: isFavorite ? "qrc:/images/starred.svg" : "qrc/images/non-starred.svg"

    text: isFavorite ? qsTr("Remove from favorites") : qsTr("Add to favorites")

    Component.onCompleted: {
        isFavorite = enabled && (AllFavoritesModel.findFavorite(model.payload) !== "")
    }

    onClicked: {
        if (isFavorite && removeFromFavorites(model.payload))
            isFavorite = false
        else if (!isFavorite && addItemToFavorites(model, description, art))
            isFavorite = true
    }
}
