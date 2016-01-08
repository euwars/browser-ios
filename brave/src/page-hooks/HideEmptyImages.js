/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

if (!_brave_replace_error_images) {
    var _brave_replace_error_images = function() {
        Array.from(document.querySelectorAll('img')).forEach(function (img) {
            img.addEventListener('error', function() {
                this.style.visibility = 'hidden'
            })
        })
    }
    document.addEventListener('DOMContentLoaded', _brave_replace_error_images)
}


