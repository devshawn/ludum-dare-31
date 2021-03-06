;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname game) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp")))))
; Ludum Dare 31
; devshawn

(define width 600)
(define height 600)
(define bg (bitmap "images/bg.png"))
(define blank-scene bg)
(define speed 5)
(define bulletspeed 3)
(define bulletlimit 10)
(define enemyspeed 1)
(define world-scale 1)
(define blockk (bitmap "images/wall.png"))
(define bulletimg (bitmap "images/bullet.png"))
(define enemyimg (bitmap "images/snowman-front.png"))
(define playerimg (bitmap "images/player-front.png"))
(define game-overlay (bitmap "images/overlay.png"))
(define start-time (current-seconds))
(define (time-elapsed x) (- (current-seconds) start-time))

(define-struct player [x y direction])
(define-struct block [x y width height image])
(define-struct bullet [x y rotate])
(define-struct keys [left right up down pause])
(define-struct enemy [x y type])
(define-struct img [left right up down])
(define-struct world [player bullets enemies blocks keys tick score started]) ; player, list of bullets, list of enemies, list of blocks, keys, number, number

(define imageset-player (make-img (bitmap "images/player-left.png") 
                                  (bitmap "images/player-right.png") 
                                  (bitmap "images/player-back.png") 
                                  (bitmap "images/player-front.png")))

(define default-player (make-player (/ width 2) (/ height 2) "down"))
(define default-keys (make-keys false false false false false))
(define default-blocks (list (make-block 4 4 1 1 blockk) (make-block 4 5 1 1 blockk) (make-block 4 6 1 1 blockk)))

(define (main duration)
  (big-bang (make-world default-player empty (list (make-enemy 100 100 1)) empty default-keys 0 0 false)
            [to-draw show]
            [on-tick tick 0.02 duration]
            [name "Snowball Fight - Ludum Dare 31 - by devshawn"]
            [on-key key-handler]
            [on-mouse mouse-handler]
            [on-release key-release-handler]
            [stop-when check-player show-end]))

(define (show ws)
  (show-start ws (show-paused ws (show-player (world-player ws) (show-bullets (world-bullets ws) (show-enemies (world-enemies ws) (show-blocks (world-blocks ws) (scale world-scale blank-scene))))))))

(define (show-start ws base)
  (cond
    [(not (world-started ws))
     (place-image (scale world-scale (start-text ws)) (/ width 2) (/ height 2)
     (place-image (scale world-scale game-overlay) (/ (image-width game-overlay) 2) (/ (image-height game-overlay) 2) base))]
    [else base]))

(define (show-paused ws base)
  (cond
    [(keys-pause (world-keys ws)) (place-image (scale world-scale game-overlay) (/ (image-width game-overlay) 2) (/ (image-height game-overlay) 2) base)]
    [else base]))

(define (show-player player base)
  (place-image (scale world-scale (get-player-image player)) (player-x player) (player-y player) base))

(define (get-player-image player)
  (cond
    [(string=? (player-direction player) "up") (img-up imageset-player)]
    [(string=? (player-direction player) "left") (img-left imageset-player)]
    [(string=? (player-direction player) "right") (img-right imageset-player)]
    [else (img-down imageset-player)]))

(define (show-bullets lob base)
  (cond
    [(empty? lob) base]
    [else (place-image (scale world-scale (rotate (bullet-rotate (first lob)) bulletimg)) 
                       (bullet-x (first lob))
                       (bullet-y (first lob))
                       (show-bullets (rest lob) base))]))

(define (show-enemies loe base)
  (cond
    [(empty? loe) base]
    [else (place-image (scale world-scale enemyimg)
                       (enemy-x (first loe))
                       (enemy-y (first loe))
                       (show-enemies (rest loe) base))]))

(define (show-blocks lob base)
  (cond
    [(empty? lob) base]
    [else (place-image (scale world-scale (block-image (first lob))) 
                       (- (* (block-x (first lob)) (image-width (block-image (first lob)))) (/ (image-width (block-image (first lob))) 2))
                       (- (* (block-y (first lob)) (image-height (block-image (first lob)))) (/ (image-height (block-image (first lob))) 2))
                       (show-blocks (rest lob) base))]))

(define (show-end ws)
  (place-image
   (scale world-scale (kills-text ws))
   (/ width 2)
   (- (/ height 2) 30)
   (place-image
    (scale world-scale (survive-text ws))
    (/ width 2)
    (+ (/ height 2) 20)
    (place-image (scale world-scale game-overlay) (/ (image-width game-overlay) 2) (/ (image-height game-overlay) 2) (show ws)))))

(define (tick ws)
  (cond
    [(not (world-started ws)) ws]
    [(keys-pause (world-keys ws)) ws]
    [else (check-collision (make-world 
                            (move ws) 
                            (move-bullets (world-bullets ws)) 
                            (move-enemies ws (add-enemy ws)) 
                            (world-blocks ws) 
                            (world-keys ws) 
                            (+ (world-tick ws) 1)
                            (world-score ws)
                            (world-started ws)))]))

(define (add-enemy ws)
  (cond
    ;[(> (random 100) 98) (cons (make-enemy (- (random (+ width 30)) 30) -30 1) (world-enemies ws))]
    [(> (remainder (world-tick ws) 100) 98) (cons (make-enemy (- (random (+ width 30)) 30) -30 1) (world-enemies ws))]
    [(and (> (world-tick ws) 1500) (> (remainder (+ 50 (world-tick ws)) 100) 98)) (cons (make-enemy (- (random (+ width 30)) 30) (+ 30 height) 1) (world-enemies ws))]
    [else (world-enemies ws)]))

(define (move ws)
  (cond
    [(and (keys-left (world-keys ws)) (> (player-x (world-player ws)) 0)) (make-player (- (player-x (world-player ws)) speed) (player-y (world-player ws)) "left")]
    [(and (keys-right (world-keys ws)) (< (player-x (world-player ws)) width)) (make-player (+ (player-x (world-player ws)) speed) (player-y (world-player ws)) "right")]
    [(and (keys-up (world-keys ws)) (> (player-y (world-player ws)) 0)) (make-player (player-x (world-player ws)) (- (player-y (world-player ws)) speed) "up")]
    [(and (keys-down (world-keys ws)) (< (player-y (world-player ws)) height)) (make-player (player-x (world-player ws)) (+ (player-y (world-player ws)) speed) "down")]
    [else (world-player ws)]))

(define (move-enemies ws loe)
  (move-enemies-helper ws loe))

(define (move-enemies-helper ws loe)
  (cond
    [(empty? loe) empty]
    [else (cons (make-enemy 
                 (+ (enemy-x (first loe)) (* (+ 1 (floor (/ (world-score ws) 10))) (cos (* (/ pi 180) (get-bullet-angle ws (enemy-x (first loe)) (enemy-y (first loe)))))))
                 (+ (enemy-y (first loe)) (* (+ 1 (floor (/ (world-score ws) 10))) -1 (sin (* (/ pi 180) (get-bullet-angle ws (enemy-x (first loe)) (enemy-y (first loe)))))))
                 (enemy-type (first loe))) 
                (move-enemies-helper ws (rest loe)))]))

(define (move-bullets lob)
  (cond
    [(empty? lob) empty]
    [(check-bullet (first lob)) (move-bullets (rest lob))]
    [else (cons (make-bullet (+ (bullet-x (first lob)) (* bulletspeed (cos (* (/ pi 180) (bullet-rotate (first lob)))) -1)) (+ (bullet-y (first lob)) (* bulletspeed (sin (* (/ pi 180) (bullet-rotate (first lob)))))) (bullet-rotate (first lob))) (move-bullets (rest lob)))]))

(define (mouse-handler ws x y mevent)
  (cond
    [(and (mouse=? "button-down" mevent) (world-started ws) (not (keys-pause (world-keys ws)))) (shoot ws x y)]
    [else ws]))

(define (check-bullet bullet)
  (cond
    [(< (bullet-x bullet) -10) true]
    [(> (bullet-x bullet) (+ (* world-scale width) 20)) true]
    [(< (bullet-y bullet) 0) true]
    [(> (bullet-y bullet) (+ (* world-scale height) 20)) true]
    [else false]))

(define (survive-text ws)
  (text (string-append "You survived " (number->string (floor (/ (world-tick ws) 50))) " seconds!") 26 "yellow"))

(define (kills-text ws)
  (text (string-append "You hit " (number->string (world-score ws)) " snowmen!") 26 "yellow"))

(define (start-text ws)
  (above (text "Hit snowmen by throwing snowballs" 26 "yellow")
         (text "Don't get hit!" 26 "yellow")
         (text "Press X to start!" 26 "yellow")))

(define (check-player ws)
  (check-player-helper (world-player ws) (world-enemies ws)))

(define (check-player-helper player loe)
  (cond
    [(empty? loe) false]
    [(and (<= (player-x player) (+ (enemy-x (first loe)) (/ (image-width enemyimg) 2)))
          (>= (player-x player) (- (enemy-x (first loe)) (/ (image-width enemyimg) 2)))
          (<= (player-y player) (+ (enemy-y (first loe)) (/ (image-height enemyimg) 2)))
          (>= (player-y player) (- (enemy-y (first loe)) (/ (image-height enemyimg) 2))))
     true]
    [else (check-player-helper player (rest loe))]))

; collision
(define (check-collision ws)
  (make-world (world-player ws) 
              (collision-bullets (world-bullets ws) (world-enemies ws)) 
              (collision-enemies (world-bullets ws) (world-enemies ws)) 
              (world-blocks ws) 
              (world-keys ws) 
              (world-tick ws)
              (+ (world-score ws) (- (length (world-enemies ws)) (length (collision-enemies (world-bullets ws) (world-enemies ws)))))
              (world-started ws)))

; returns list of enemies
(define (collision-enemies lob loe)
  (cond
    [(empty? lob) loe]
    [else (enemies-helper (first lob) (collision-enemies (rest lob) loe))]))

(define (enemies-helper bullet loe)
  (cond
    [(empty? loe) empty]
    [(and (<= (bullet-x bullet) (+ (enemy-x (first loe)) (/ (image-width enemyimg) 2)))
          (>= (bullet-x bullet) (- (enemy-x (first loe)) (/ (image-width enemyimg) 2)))
          (<= (bullet-y bullet) (+ (enemy-y (first loe)) (/ (image-height enemyimg) 2)))
          (>= (bullet-y bullet) (- (enemy-y (first loe)) (/ (image-height enemyimg) 2))))
     (enemies-helper bullet (rest loe))]
    [else (cons (first loe) (enemies-helper bullet (rest loe)))]))

; returns list of bullets
(define (collision-bullets lob loe)
  (cond
    [(empty? loe) lob]
    [else (bullets-helper (first loe) (collision-bullets lob (rest loe)))]))

(define (bullets-helper enemy lob)
  (cond
    [(empty? lob) empty]
    [(and (>= (bullet-x (first lob)) (- (enemy-x enemy) (/ (image-width enemyimg) 2)))
          (<= (bullet-x (first lob)) (+ (enemy-x enemy) (/ (image-width enemyimg) 2)))
          (>= (bullet-y (first lob)) (- (enemy-y enemy) (/ (image-height enemyimg) 2)))
          (<= (bullet-y (first lob)) (+ (enemy-y enemy) (/ (image-height enemyimg) 2))))
     (bullets-helper enemy (rest lob))]
    [else (cons (first lob) (bullets-helper enemy (rest lob)))]))

; world -> number
(define (get-bullet-angle ws x y)
  (floor (+ (* (atan (- x (player-x (world-player ws))) (- y (player-y (world-player ws)))) (/ 180 pi)) 90)))

(define (shoot ws x y)
  (if (<= (length (world-bullets ws)) bulletlimit) 
      (make-world (world-player ws) 
                  (cons (make-bullet (player-x (world-player ws)) (player-y (world-player ws)) (get-bullet-angle ws x y)) (world-bullets ws))
                  (world-enemies ws)
                  (world-blocks ws)
                  (world-keys ws)
                  (world-tick ws)
                  (world-score ws)
                  (world-started ws))
      ws))

(define (pause keys)
  (make-keys (keys-left keys) (keys-right keys) (keys-up keys) (keys-down keys) (not (keys-pause keys))))

(define (key-handler ws a-key)
  (cond
    [(key=? "w" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "w" true) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "a" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "a" true) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "s" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "s" true) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "d" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "d" true) (world-tick ws) (world-score ws) (world-started ws))]
    [(and (key=? "p" a-key) (world-started ws)) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (pause (world-keys ws)) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "x" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (world-keys ws) (world-tick ws) (world-score ws) true)]
    [else ws]))

(define (key-release-handler ws a-key)
  (cond
    [(key=? "w" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "w" false) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "a" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "a" false) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "s" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "s" false) (world-tick ws) (world-score ws) (world-started ws))]
    [(key=? "d" a-key) (make-world (world-player ws) (world-bullets ws) (world-enemies ws) (world-blocks ws) (set-key (world-keys ws) "d" false) (world-tick ws) (world-score ws) (world-started ws))]
    [else ws]))

; world-keys, string, boolean -> keys structure
(define (set-key lok key state)
  (cond
    [(string=? key "w") (make-keys (keys-left lok) (keys-right lok) state (keys-down lok) (keys-pause lok))]
    [(string=? key "a") (make-keys state (keys-right lok) (keys-up lok) (keys-down lok) (keys-pause lok))]
    [(string=? key "s") (make-keys (keys-left lok) (keys-right lok) (keys-up lok) state (keys-pause lok))]
    [(string=? key "d") (make-keys (keys-left lok) state (keys-up lok) (keys-down lok) (keys-pause lok))]))

(main 1000000000)