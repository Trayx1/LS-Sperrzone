$(document).ready(function() {
    let zones = []; // Eine Liste für die aktuell bestehenden Sperrzonen

    $('#radius').on('input', function() {
        let radiusValue = $(this).val();
        $('#radius-value').text(radiusValue + ' Meter');
    });

    // Empfang von NUI-Nachrichten zum Öffnen oder Schließen des Menüs
    window.addEventListener('message', function(event) {
        if (event.data.action === "openMenu") {
            $('body').css('display', 'flex');
            console.log("[DEBUG] Menü geöffnet.");
            updateZoneList(event.data.zones);
        } else if (event.data.action === "closeMenu") {
            $('body').css('display', 'none');
            console.log("[DEBUG] Menü geschlossen.");
        } else if (event.data.action === "addZone") {
            if (!zones.some(zone => zone.id === event.data.zone.id)) {
                zones.push(event.data.zone);
                addZoneToList(event.data.zone);
            }
        } else if (event.data.action === "removeZone") {
            removeZoneFromList(event.data.zoneId);
            zones = zones.filter(zone => zone.id !== event.data.zoneId);
        }
    });

    // ESC drücken, um das Menü zu schließen
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape') {
            $.post('https://LS-Sperrzone/closeMenu', {}, function() {
                console.log("[DEBUG] ESC-Taste gedrückt, Menü schließen.");
            }).fail(function() {
                console.error("Fehler beim Schließen über ESC.");
            });
        }
    });

    // Schließen-Button in der UI
    $('#closeBtn').click(function() {
        $.post('https://LS-Sperrzone/closeMenu', {}, function() {
            console.log("[DEBUG] Schließen-Button gedrückt.");
        }).fail(function() {
            console.error("Fehler beim Schließen über den Button.");
        });
    });

    // Sperrzone erstellen
    $('#createZone').click(function() {
        let radius = $('#radius').val();

        $.post('https://LS-Sperrzone/createZone', JSON.stringify({
            radius: radius
        }));
    });

    // Funktion zum Aktualisieren der Sperrzonen-Liste
    function updateZoneList(zonesData) {
        $('#zones-list').empty();
        zones = []; // Liste der Zonen leeren und neu aufbauen
        zonesData.forEach(zone => {
            zones.push(zone);
            addZoneToList(zone);
        });
    }

    // Sperrzone zur Liste hinzufügen
    function addZoneToList(zone) {
        let listItem = $('<li>')
            .text('Sperrzone: Radius ' + zone.radius + ' Meter')
            .attr('data-id', zone.id);

        let deleteBtn = $('<button>')
            .text('Löschen')
            .click(function() {
                let zoneId = $(this).parent().attr('data-id');

                $.post('https://LS-Sperrzone/deleteZone', JSON.stringify({
                    id: zoneId
                }));
            });

        listItem.append(deleteBtn);
        $('#zones-list').append(listItem);
    }

    // Sperrzone aus der Liste entfernen
    function removeZoneFromList(zoneId) {
        $('#zones-list').find('[data-id="' + zoneId + '"]').remove();
    }
});
