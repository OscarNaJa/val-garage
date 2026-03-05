window.addEventListener('message', function(event) {
    if(event.data.action == 'SHOW'){
        $('.press_txt p').html(event.data.isPress)
        $('.container_press_ui').css('animation','anim_in .2s forwards')
        $('.display_press_ui').fadeIn()
        $('.press_detail').html(`
            <p>${event.data.text}</p>
        `)
        
        setTimeout(() => {
            const audio = new Audio();
            audio.src = "./sound/open.wav";
            audio.play()
            audio.volume = 0.2;
        }, 150);

    }
    else if (event.data.action == 'HIDE'){
        $('.container_press_ui').css('animation','anim_out .2s forwards')
        $('.display_press_ui').fadeOut(100)
    }
   
})