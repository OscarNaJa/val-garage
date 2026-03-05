var element = document.getElementById('myElement');
let detailDisplay = false
let renameDisplay = false
fav = JSON.parse(localStorage.getItem("fav-list"));
let favSelect = false
let canClick = true
let nowPlateEdit = ''
let pounddeposit = false

document.querySelector('#search').addEventListener('input', filterList)

function filterList() {
    const searchInput = document.querySelector("#search")
    const filter = searchInput.value.toLocaleLowerCase()
    const listItem = document.querySelectorAll('.car_box')

    listItem.forEach((item) => {
        let text = item.querySelector('.car_name').textContent
        if (text.toLowerCase().includes(filter.toLowerCase())) {
            item.style.display = ''
            // if($(item).hasClass('empty_block')){
            //     item.style.display = 'none'
            // }
        } else {
            item.style.display = 'none'
        }

    })
}


let nowGarage

function getPosition(element) {
    var rect = element.getBoundingClientRect();
    return {
        x: rect.left,
        y: rect.top
    };
}
$('body').on('click', '.container', function () {
    if (detailDisplay) {
        detailDisplay = false
        $('.car-list').removeClass('active')
        $('.add-detail').hide()
    }

})
$('.car-strage').on('scroll', function () {
    if (detailDisplay) {
        detailDisplay = false
        $('.car-list').removeClass('active')
        $('.add-detail').hide()
    }

})



$('body').on('click', '.vehicle-detail2', function () {
    if (canClick == true) {
        canClick = false
        $.post(`https://${GetParentResourceName()}/trunkopen`, JSON.stringify({
            plate: $(this).parent().parent().attr('data-plate')
        }), function (cb) {
            if (cb == 'success') {
                UICLOSE()
                // $('.assist_garage').fadeOut()
                detailDisplay = false
            } else {
                notishow('ไม่สามารถเปิดท้ายรถคันนี้ได้')
            }
        });
        setTimeout(() => {
            canClick = true
        }, 400);
    }
})

$('body').on('click', '.spawn', function () {
    if (canClick == true) {
        canClick = false
        $.post(`https://${GetParentResourceName()}/spawnvehicle`, JSON.stringify({
            plate: $(this).parent().parent().attr('data-plate')
        }), function (cb) {
            if (cb == 'success') {
                $('.add-detail').fadeOut()
                UICLOSE()
                // $('.assist_garage').fadeOut()
                detailDisplay = false
            } else {
                notishow('คูณมีเงินไม่เพียงพอในการพาวน์')
            }
        });
        setTimeout(() => {
            canClick = true
        }, 400);
    }
})

$('body').on('click', '.edit', function () {

    if (renameDisplay == false) {
        if (canClick == true) {
            canClick = false
            renameDisplay = true
            nowPlateEdit = $(this).attr('data-plate-rename')
            $('.car-list').removeClass('active')
            $('.add-detail').hide()
            detailDisplay = false
            $('.display-input').fadeIn()
            setTimeout(() => {
                canClick = true
            }, 400);
        }
    }
})

$('body').on('click', '.exit-area', function () {
    if (renameDisplay) {
        renameDisplay = false
        $('.display-input').fadeOut()
    } else {
        if (detailDisplay) {
            detailDisplay = false
            $('.car-list').removeClass('active')
            $('.add-detail').hide()
        } else {
            UICLOSE()
            // $('.assist_garage').hide()
            $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({
                plate: $(this).attr('data-plate-spawn')
            }))
        }
    }
})

$('body').on('click', '.submit-btn', function () {
    value = document.getElementById('name-input').value
    if (value.length <= 2) {
        notishow('ตัวอักษรของคุณน้อยเกินไป')

    } else if (value.length >= 12) {
        notishow('ตัวอักษรของคุณมากเกินไป')

    } else {
        renameDisplay = false
        $('.display-input').fadeOut()
        $.post(`https://${GetParentResourceName()}/changeName`, JSON.stringify({
            plate: nowPlateEdit,
            rename: $('#name-input').val()
        }));
    }
})

$('body').on('click', '.send', function () {
    if (canClick == true) {
        canClick = false
        $.post(`https://${GetParentResourceName()}/sendvehicle`, JSON.stringify({
            plate: $(this).attr('data-plate-send')
        }), function (cb) {
            if (cb == 'success') {
                $('.car-list').removeClass('active')
                $('.add-detail').fadeOut()
                // $('.container').fadeOut()
                detailDisplay = false
            } else {
                notishow('คูณมีเงินไม่เพียงพอที่จะส่งรถเข้าการาจ')
            }
        });
        setTimeout(() => {
            canClick = true
        }, 400);
    }
})

$('body').on('click', '.fav-btn', function () {
    if ($(this).parent().hasClass('favorite')) {
        $(this).parent().removeClass('favorite')
        plate_fav = $(this).attr('data-plate-fav')

        // fav = !fav ? [] : fav;
        let taskInfo = { plate: plate_fav };
        fav.splice(fav.indexOf(plate_fav), 1);
        // fav.push(taskInfo)
        localStorage.setItem("fav-list", JSON.stringify(fav))
        $(this).parent().css('order', '2')
    } else {
        $(this).parent().addClass('favorite')
        plate_fav = $(this).attr('data-plate-fav')
        fav = !fav ? [] : fav;
        let taskInfo = plate_fav;
        fav.push(taskInfo)
        $(this).parent().css('order', '1')
        localStorage.setItem("fav-list", JSON.stringify(fav))
    }

    // $.post(`https://${GetParentResourceName()}/reloadVehicleData`, JSON.stringify({}))
});

document.onkeyup = function (data) {
    if (data.which == 27) {
        if (renameDisplay) {
            $('.display-input').fadeOut(300);
            renameDisplay = false
        } else {
            if (detailDisplay) {
                detailDisplay = false
                $('.car-list').removeClass('active')
                $('.add-detail').hide()
            } else {
                UICLOSE()
                // $('.assist_garage').hide()
                $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({
                    plate: $(this).attr('data-plate-spawn')
                }))
            }
        }

    }
}

function disableselect(e) {
    return false
}

function reEnable() {
    return true
}
document.onselectstart = new Function("return false")
if (window.sidebar) {
    document.onmousedown = disableselect
    document.onclick = reEnable
}

function UICLOSE() {
    $('.assist_garage').fadeOut()
}
window.addEventListener('message', function (event) {
    if (event.data.action == 'open') {
        $('.assist_garage').fadeIn()
    }
    if (event.data.action == 'closeui') {
        UICLOSE()
        // $('.assist_garage').fadeOut()
        detailDisplay = false
    }

    if (event.data.action == 'pounddeposit') {
        pounddeposit = event.data.pounddeposit
    }
    if (event.data.action == 'syncData') {
        $('.assist_content').empty()
        $('.category').removeClass('select_category')
        $('.category:first').addClass('select_category')
        nowGarage = event.data.type
        var allVehicle = 0
        var garageCount = 0
        var poundCount = 0
        var favCount = 0
        // 
        $('.add-detail').removeClass('deposit')
        $('.add-detail').removeClass('garage')
        $('.add-detail').removeClass('pound')

        $('#title-garage').html(nowGarage.toUpperCase())
        let elementTRUNK = `
             <div class="button_trunk vehicle-detail2">
                            <iconify-icon icon="mdi:bag-personal"></iconify-icon>
                        </div>
        `
        // let textnotaction = 'garage'
        // if (nowGarage == 'garage') {
        //     textnotaction = 'impounded'
        // }
        // if (nowGarage == 'pound') {
        //     elementTRUNK = ''
        // }
        for (key in event.data.data) {
            allVehicle = allVehicle + 1
            var fuel = 0
            var engine = 0
            let classMenu = 'pound'
            let textnotaction = 'GARAGE'

            if (event.data.data[key].fuel) {
                fuel = (event.data.data[key].fuel).toFixed(0)
            }
            if (nowGarage == 'garage') {
                if (event.data.data[key].deposit) {
                    textnotaction = `DEPOSIT ${event.data.data[key].deposit}`;
                } else {
                    textnotaction = 'IMPOUNDED'
                }
                // textnotaction = 'IMPOUNDED'

            }
            if (nowGarage == 'pound') {
                elementTRUNK = ''
            }
            if (event.data.data[key].engine) {
                engine = (event.data.data[key].engine).toFixed(0)
            }

            if (pounddeposit) {
                if (event.data.data[key].stored) {
                    if (event.data.data[key].deposit) {
                        poundCount = poundCount + 1
                    } else {
                        classMenu = 'garage'
                        garageCount = garageCount + 1
                    }
                } else {
                    poundCount = poundCount + 1
                }
            } else {
                if (event.data.data[key].stored) {
                    classMenu = 'garage'
                    garageCount = garageCount + 1
                    if (event.data.data[key].deposit) {
                        textnotaction = `DEPOSIT ${event.data.data[key].deposit}`;
                    }
                } else {

                    poundCount = poundCount + 1
                }
            }
            let nowFav = ''
            let order = 2
            if (fav) {
                fav.forEach((fav) => {
                    if (fav == event.data.data[key].plate) {
                        nowFav = 'favorite'
                        order = 1
                        favCount = favCount + 1
                    }

                })
            }

            $('.assist_content').append(`
                    <div class="car_box ${nowFav} ${classMenu}" style = "order:${order}"data-fav="${nowFav}" data-plate = "${event.data.data[key].plate}" data-vehiclename = "${event.data.data[key].vehiclename}" data-fuel = "${fuel}" data-engine = "${engine}" style="--data-txt:'${textnotaction.toUpperCase()}'" data-speed = "${event.data.data[key].maxspeed}" data-acc = "${event.data.data[key].maxacc}" data-break = "${event.data.data[key].maxbreak}" data-weight ="${event.data.data[key].weight}">
                        <div class="assist_pound">
                            <iconify-icon icon="uil:car-slash"></iconify-icon>
                            <p>THIS VEHICLE HAS BEEN ${textnotaction}.</p>
                        </div>
                        <div class="car_name">
                            <p>${event.data.data[key].vehiclename}</p>
                            <p>${event.data.data[key].plate}</p>
                            <p>${(event.data.data[key].class)}</p>
                        </div>
                        <div class="car_img">
                            <img src="img/${event.data.data[key].img}.png" alt="">
                        </div>
                        <div class="car_console">
                         ${elementTRUNK}
                            <div class="button_spawn spawn">
                            <iconify-icon icon="material-symbols:garage-home-rounded"></iconify-icon>
                                <p>SPAWN</p>
                            </div>
                           
                        </div>
                        <div class="assist_favorite_btn fav-btn" data-plate-fav = "${event.data.data[key].plate}">
                            <iconify-icon icon="clarity:favorite-solid"></iconify-icon>
                        </div>
            
                        <div class="car_health_list">
                            <div class="car_box_list">
                                <iconify-icon icon="mdi:hammer-wrench"></iconify-icon>
                            
                                <div class="car_number">
                                    <p>${engine}</p>
                                </div>
                               
                            </div>
                            <div class="car_box_list">
                                <iconify-icon icon="mdi:fuel-pump"></iconify-icon>
                                 <div class="car_number">
                                    <p>${fuel}</p>
                                </div>
                               
                            </div>
                        </div>
                    </div>
            `)
        }
        $('.car_img img').on('error', function () {
            $(this).attr('src', 'img/unknow.png')
        });
        // ก่อนเติม ต้องลบกล่องเปล่าเดิมก่อน
        $('.assist_content .empty_block').remove();
        if (5 - allVehicle > 0) {
            for (let i = 0; i < 5 - allVehicle; i++) {
                $('.assist_content').append(`<div class="car_box empty_block" style = "order: 4 ">
                 <iconify-icon icon="octicon:x-12" class="empty_icon"></iconify-icon>
                </div>`)
            }
        }
        // เพิ่ม empty block เฉพาะตาม class garage
        if (5 - garageCount > 0) {
            for (let i = 0; i < 5 - garageCount; i++) {
                $('.assist_content').append(`<div class="car_box empty_block garage" style="order: 4">
                    <iconify-icon icon="octicon:x-12" class="empty_icon"></iconify-icon>
                </div>`);
            }
        }

        // เพิ่ม empty block เฉพาะตาม class pound
        if (5 - poundCount > 0) {
            for (let i = 0; i < 5 - poundCount; i++) {
                $('.assist_content').append(`<div class="car_box empty_block pound" style="order: 4">
                    <iconify-icon icon="octicon:x-12" class="empty_icon"></iconify-icon>
                </div>`);
            }
        }
        $('.car_box.empty_block.garage').hide();
        $('.car_box.empty_block.pound').hide();
        if (nowGarage == 'garage') {

            $('.car_box.garage').removeClass('car_inpound')
            $('.car_box.pound').addClass('car_inpound')
            $('.car_box.pound').css('order', '3')

        } else {
            $('.car_box.pound').removeClass('car_inpound')
            $('.car_box.garage').addClass('car_inpound')
            $('.car_box.garage').css('order', '3')
        }
    }

})

$('body').on('click', '.category', function () {
    let typemenu = $(this).attr('data-menu')
    $('.category').removeClass('select_category')

    $(this).addClass('select_category')
    if (typemenu == 'all') {
        $('.car_box').show()
        $('.car_box.empty_block.garage').hide();
        $('.car_box.empty_block.pound').hide();
    } else {
        $('.car_box').hide()
        $('.car_box.' + typemenu).show()
    }
})

function notishow(text) {
    $('.noti-show').fadeIn()
    $('.input-alert p').html(text)
    setTimeout(() => {
        $('.noti-show').fadeOut()
    }, 3500);
}