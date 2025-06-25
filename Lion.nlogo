;----------------------------- Global definitions -----------------------------
;Global variables:
; - wildebeestseatenbylions: number of wildebeests eaten by lions
; - wildebeestsdrowned: number of wildebeests drowned
; - cont: variable to count the number of sub-heards until reaching the full herd size
; - crowding?: is time to flocking crowding to the river banks while waiting for the leaders choice?
; - firstleader?: is the wildebeest a hypotetic first leader?
; - approachpoint: river approach point for the herd (first leader choose it)
; - lionsattacks: number of lion's attacks
globals [escape-heading wildebeestseatenbylions wildebeestseatenbycrocs wildebeestsdrowned cont crowding? firstleader? approachpoint lionsattacks upper-river lower-river]
;Define new turtle breed: Wildebeest, Lions
breed [wildebeests wildebeest] ;[plural singolar]
breed [lions lion]
breed [lionesses lioness ]
; Wildebeests-only characteristics:
; - target: their prior target before following each other
; - waitforleadership: counter to force wildebeests to wait until some wildebeest choose to be leader
; - leadership?: leader or not leader?
; - flockmates, nearest-neighbor: flocking parameters
; - status: movement status of the wildebeest:
;           0 - before the river: flocking as a compact herd
;           1 - near to the river: crowding on the river bank and wait for the leaders choice
;           2 - crossing the river: flocking more slowly, forming a single row or a couple of rows
;           3 - over the river: flocking spreading a bit more facing the target
;           4 - lion alert --> evasion
;           5 - lion no more a alert --> pursuit
;           6 - stop status: job done --> set agent as hidden
; - crossing?: is the wildebeest crossing the river?
; - timealone: time alone in water
; - firstimeatacked?: is the first time (of each attack) that the wildebeest notice the predator?
; Assumption: a wildebeest die if spend to much time alone (herd effect)
wildebeests-own [target waitforleadership leadership? flockmates nearest-neighbor status firsttimeattacked? tutti? waitingtime wiggle-ampl]
lions-own [status waitingtime accelerationtime firsttimeattack?]
lionesses-own [status waitingtime accelerationtime flockmates nearest-neighbor group-target]

;------------------------------ Setup functions -------------------------------
; Functions to setup the environment (background and parameters)

; Setup the environment
to setup
  ; Remove old agents
  clear-all
  ask patches [ set pcolor brown + 2 ]

  ;background
  import-background
  set upper-river max [pycor] of patches with [on-water?]
  set lower-river min [pycor] of patches with [on-water?]
  ; Define wildebeests default area
  ;let patches-in-box patches with [pxcor > 100 and pycor < -100 ] ;100 -100
  ; Set number of initial sub-group (100k each subgroup) of wildebeests
  set cont 1
  let patches-in-box patches with [pxcor > -20 and pxcor < 20 and pycor < -60 and pycor > -80] ;100 -100
  let patches-in-box-lion patches with [pxcor > -20 and pxcor < 20 and pycor < -50 and pycor > -80] ;100 -100
  ; Call to wildebeests generator with default area as parameter
  wildebeest-generator (patches-in-box)
  ; Set crowding? as initially false
  set crowding? false
  ; Set firstleader? as initially false
  set firstleader? true
  ; Call to lions generator
  lions-generator
  ; Call to lionesses generator
  lionesses-generator
  ; Reset ticks to start a new simulation
  reset-ticks
end



;; genera un gruppo di gnu fra i due fiumi
; Generate wildebeest and distribute them normally in the bottom-right corner
to wildebeest-generator [box]
  ; Default shape for wildebeests agent
  set-default-shape wildebeests "cow"
  ; Number of wildebeests
  let pop wildebeests-number
  let ys [ pycor ] of box
  let xs [ pxcor ] of box
  let min-x min xs
  let min-y min ys
  let max-x max xs
  let max-y max ys
  let mid-x mean list min-x max-x
  let mid-y mean list min-y max-y
  let w max-x - min-x
  let h max-y - min-y
  ; Create "pop" wildebeests
  create-wildebeests pop [
    loop [
      ; Default charactertistics and parameters
      set size 3.5
      set color black
      set status 0
      set waitforleadership 0
      ; Default leadership value --> no default leaders, choosen at the crossing moment
      set leadership? false
      set tutti? true

      set firsttimeattacked? true
      set flockmates no-turtles
      ; Set normally distributed position in the default area
      ; OBS: normal cause replicate better a herd than a uniform
      let x random-normal mid-x (w / 6)
      if x > max-x [ set x max-x ]
      if x < min-x [ set x min-x ]
      set xcor x
      let y random-normal mid-y (h / 6)
      if y > max-y [ set y max-y ]
      if y < min-y [ set y min-y ]
      set ycor y
      if not any? other turtles-here [ stop ]
    ]
    ; Center in patch
    move-to patch-here
]

end




to lions-generator
  if lions? [
    set-default-shape lions "lion"
;    ;; 1) ascissa media del branco di gnu
;    let herd-x mean [xcor] of wildebeests
;    ;; 2) soglia orizzontale per distinguere nord vs sud
;    let mid-water-y mean [pycor] of patches with [on-water?]
;    ;; coordinata x che separa sinistra/destra
;    let mid-x (min-pxcor + max-pxcor) / 2
;
;
;    ;; 3) rive “sud del fiume nord” FUORI dal corridoio ±50
;    let north-bank patches with [
;      not on-water?
;      and patch-at 0 1 != nobody
;      and [on-water?] of patch-at 0 1
;      and [pycor] of patch-at 0 1 > mid-water-y
;      and abs(pxcor - herd-x) > 40
;      and abs(pxcor - herd-x) < 50
;      and pxcor > mid-x
;    ]

      ; sud del fiume nord
;      let nb-center one-of north-bank
;      let nx [pxcor] of nb-center
;      let ny [pycor] of nb-center
      create-lions lions-number [
        set firsttimeattack? true
        set size 3.5
        set color red
        set status 0
        set accelerationtime 0
        set waitingtime 0
        let placed? false
        ;while [not placed?] [
          let x  42
          let y  -12
          let p patch x y
          move-to p
        set placed? true
;          if p != nobody and not [on-water?] of p [
;            move-to p
;            set placed? true
;          ]
        ]

    ]

end


to lionesses-generator
  if lionesses? [
    set-default-shape lionesses "lion"
    let herd-x mean [xcor] of wildebeests
    let mid-water-y mean [pycor] of patches with [on-water?]
    let mid-x (min-pxcor + max-pxcor) / 2

    let north-bank patches with [
      not on-water?
      and patch-at 0 1 != nobody
      and [on-water?] of patch-at 0 1
      and [pycor] of patch-at 0 1 > mid-water-y
      and abs(pxcor - herd-x) > 40
      and abs(pxcor - herd-x) < 50
      and pxcor > mid-x
    ]


    if any? north-bank [
      let nb-center one-of north-bank
      let nx [pxcor] of nb-center
      let ny [pycor] of nb-center
      create-lionesses lionesses-number [
        set size 3.5
        set color yellow
        set status 0
        set accelerationtime 0
        set waitingtime 0
        let placed? false
        while [not placed?] [
          let x random-normal nx 2
          let y random-normal ny 2
          let p patch x y
          if p != nobody and not [on-water?] of p [
            move-to p
            set placed? true
          ]
        ]
      ]
    ]
  ]
end
;-------------------------------- SETUP --------------------------------





to import-background
  import-pcolors "img/GrumetiDL2.png"
end

;-------------------------------- Go functions --------------------------------
; Functions to handle simulation tick by tick

; Ticks function --> "main"
to go
  if not any? turtles [ stop ]
  ; Call to go function for wildebeests
  go-wildebeests
  ; Call to go function for wildebeests
  go-lions
  go-lionesses
  tick
end

; ---------------------- COMPORTAMENTO DEGLI ANIMALI ---------------------------
to go-wildebeests
  ask wildebeests [
    set wiggle-ampl 8           ;; ampiezza massima ±8°
  ]

    ask wildebeests [
    ifelse status != 4 [
      ; if not hidden (job done status)
      if status != 2[
        ; if not in evasion face a random target (over the river)
        ;commento in quanto lentissimo come codice
;        if any? patches in-radius 50 with [on-water?] [
;        let nearest-water min-one-of patches in-radius 50 with [on-water?] [distance myself]
;        face nearest-water
;        ]

        ;punta nord
;        set target patch (random-int-between -80 120) 120
;        face target
      ]
      ; Eevasive wildebeest that change to status 2 cause finish to cross the river and forget to be in status 4
      if color = green [
        set status 2
      ]
      ; Wildebeest in pursuit that change to status 3 cause finish to cross the river and forget to be in status 5
      if color = blue [
        set status 3
      ]
      ; Set number of leaders (can be more then 1, but not too much, cause when wildebeests are in the water
      ; the ones on the banks simply follow the herd and not the leaders anymore)
      let number-of-leaders random-int-between 1 5
      ; 0) Default Status: 0 - before arriving at the river banks
      ; 1) Check if Status is 1
      let closetowater? (count patches in-radius 3 with [on-water?] > 0 and status = 0)
      if closetowater? [
        set status 1
      ]
      ; 3) Check if Status is 3
;      if (on-water? = false) and crossing? [
;        set status 3
;        set crossing? false
;      ]
      ; 4) Check if status is 4
      ; OBS: lions attack a wildebeest from radius 12, but wildebeest see it only in radius 10
      ;  why? wildebeests, that are usually vigilant, are less vigilant if they're migrating
      ifelse high-grass[
        if any? (turtle-set lions lionesses) in-radius 10 [
        set status 2
      ]
      ][
        if any? (turtle-set lions lionesses) in-radius 20 [
        set status 2
      ]
      ]
      ; 5) Check if status is 6
      let closetowaterfuga? (count patches in-radius 3 with [on-water?] > 0)
      if ycor < -70 and closetowaterfuga?[
        set status 4
      ]
      ;Status 0: normal flocking before the river banks
      if status = 0 [
        set target patch (random-int-between -80 120) 120
        face target
          ; if not, default flocking, quite compact herd in march
          to-flock 1 2 5 4 ;min-sep, sep, ali, coh
          fd 0.01
      ]
      ; Status 1: near the river bank
      if status = 1 [
        ;; 1) Se hai fatto un passo in acqua, torna immediatamente indietro
        if on-water? [
          bk 0.5                       ;; mezzo passo sulla terraferma
          ;rt 90                        ;; orientati parallelo al fiume
        ]

        ;; 2) Mantieni distanza per evitare sovrapposizioni
        to-flock 2 4 1 0              ;; min‑sep 2, separazione forte, quasi zero coesione
        if any? other wildebeests in-radius 2 [
          rt random 360
          fd 0.03                      ;; spostati su un’altra patch
        ]

        ;; 3) Avanza lentamente lungo la riva (niente attraversamento)
        fd 0.01

      ]
   ; Status 2: predation --> evasion
      if status = 2 [
        ask wildebeests with [status != 2 and status != 3] [
          if tutti?[
            set status 2
            set color green
          ]
        ]
        set color green
        ; escape
        ifelse firsttimeattacked? [
          ; escape to the right
          ifelse count [turtles-on patch-set (list patch-at 1 0 patch-at -1 0 patch-at -1 -1)] of self < 1 [
            let goal patch -120 -120
            let desired-heading towards goal
            ;; mescola 80% direzione al goal + 20% virata casuale
            set heading 0.8 * desired-heading + 0.3 * (heading + random wiggle-ampl * 2 - wiggle-ampl)
            fd 0.01
          ] [
            ;escape to the left
            let goal patch 0 -120
            let desired-heading towards goal
            ;; mescola 80% direzione al goal + 20% virata casuale
            set heading 0.8 * desired-heading + 0.3 * (heading + random wiggle-ampl * 2 - wiggle-ampl)
            fd 0.01
          ]
          set firsttimeattacked? false
        ] [
          ;set heading (heading + random-int-between -10 10)
          let base-speed       0.025         ;; velocità massima
          let slowdown-start   200          ;; quanti tick restare al massimo
          let slowdown-end     500          ;; tick in cui si raggiunge la minima
          let min-speed        0.01         ;; non scendere oltre questo

          let slow-factor 0
          if waitingtime > slowdown-start [
            set slow-factor (waitingtime - slowdown-start) /
            (slowdown-end   - slowdown-start)
            set slow-factor min list 1 slow-factor          ;; clamp 0‒1
          ]

          let speed max list min-speed (base-speed * (1 - slow-factor))
          fd speed
        ]
        ; if no more hungry lions near to you --> pursuit until reach again the herd
        if count lions with [status != 4] in-radius 10 < 1 [
          ; pursuit mode
          set status 3
          set firsttimeattacked? true
          set tutti? false
        ]
      ]
      ; Status 3: pursuit mode
      if status = 3 [
        ; come back to the herd
        set color blue
        ;let the-herd (one-of wildebeests in-radius 50)
        ;face the-herd
        ; if about to catch up with the herd, don't pass the leader, only pull even with it
;        ifelse distance the-herd > 1 [
;          fd 0.12
;        ][
;          move-to the-herd
        to-flock 1 2 5 4 ;min-sep, sep, ali, coh
        fd 0.015
        face patch (random-int-between -80 120) -120

          ;set color black
          ; Back to the status of the herd
          ;set status [status] of the-herd

      ]


    ] [
      if on-water? [
          bk 0.5                       ;; mezzo passo sulla terraferma
          ;rt 90                        ;; orientati parallelo al fiume
        ]

        ;; 2) Mantieni distanza per evitare sovrapposizioni
        to-flock 2 4 1 0              ;; min‑sep 2, separazione forte, quasi zero coesione
        if any? other wildebeests in-radius 2 [
          rt random 360
          fd 0.03                      ;; spostati su un’altra patch
        ]
    ]
  ]
end




; Go function for lions
to go-lions
  ask lions [
    ; Assumption: no lions on water
    ;; Solo quando il leone è su acqua
    if on-water? [
      ;; Controlla il patch che sta a 1 passo davanti
      let davanti patch-ahead 1
      ifelse (davanti != nobody and [on-water?] of davanti) [
        ;; Se davanti c'è ancora acqua, indietreggia e gira un po'
        fd -0.05
        rt random-int-between -20 20
      ] [
        ;; Altrimenti (sta dando le spalle all’acqua), avanza verso terra
        fd 0.05
      ]
    ]
  ]
  ifelse high-grass[
    ask lions[

    ; Status 0: relax, random walk before a alert
    if status = 0 [
      rt random-int-between -10 10
      ;fd 0.01
      ; Check for a possible alert
      let possiblewildebeest one-of wildebeests in-radius 35
      if possiblewildebeest != nobody and firsttimeattack? [
        ; if alert
        face possiblewildebeest
        set status 1
      ]
    ]
    ; Status 1: alerted, face the possible prey and slowly try to get near to it/them
    ; OBS: not a real ambush, cause when wildebeests migrate they're too much annd they also ignore more predators
    if status = 1 [
      ;; cerca uno gnu entro raggio 50
      let possiblewildebeest one-of wildebeests with [status = 1] in-radius 35
      ifelse possiblewildebeest != nobody and firsttimeattack? [
        ;; orientati verso lo gnu
        face possiblewildebeest
        fd 0.02
        ;; avanza lentamente solo se lo gnu è su acqua


        ;; se trovi uno gnu isolato (meno di 3 nel raggio 2) entro 12 passi, vai a targeting
        let probablewildebeest one-of wildebeests with [status = 1] in-radius 15
        if probablewildebeest != nobody and firsttimeattack? [
          face probablewildebeest
          set status 2
        ]
      ] [
        ;; se lo gnu è sparito, torna a relax
        set status 0
      ]
    ]
    ; Status 2: targeting mode, near to on or more target prey, wait until try to attack
    if status = 2 [
      ; try to attack (if exist a real target: wildebeest in radius 5 with only 1 neighbor)
      let prey one-of wildebeests in-radius 25
      ifelse prey != nobody and firsttimeattack? [
        ; Approach the target if is enough alone
        face prey
        fd 0.01
        set status 3
      ] [
;        ; Wait for attack
        set waitingtime waitingtime + 1
        let prey2 one-of wildebeests in-radius 5
        if prey2 = nobody [
          ; Prey no more killable --> wrong targeting
          set status 1
        ]
        if waitingtime > 100 [
          ; Impossible targeting, give up for the moment
          set status 1
          set waitingtime 0
        ]
      ]
    ]
    ; Status 3: try to kill
    if status = 3 [
      ; try to kill
      set lionsattacks (lionsattacks + 1)
      set waitingtime waitingtime + 1
      set color yellow
      ;; ------------------------------------------------------------------
      let base-speed       0.017         ;; velocità massima
      let slowdown-start   1500          ;; quanti tick restare al massimo
      let slowdown-end     2500          ;; tick in cui si raggiunge la minima
      let min-speed        0.005         ;; non scendere oltre questo

      let slow-factor 0
      if waitingtime > slowdown-start [
        set slow-factor (waitingtime - slowdown-start) /
        (slowdown-end   - slowdown-start)
        set slow-factor min list 1 slow-factor          ;; clamp 0‒1
      ]

      let speed max list min-speed (base-speed * (1 - slow-factor))
      fd speed
      ;; ---------------------------------------------------------
      let prey one-of wildebeests
      ifelse prey != nobody and firsttimeattack? [
        face prey
        fd speed
        if [distance myself] of prey < 1 [
          ; predation
          ask prey [ die ]
          set wildebeestseatenbylions wildebeestseatenbylions + 1
          set status 4
        ]

        while [status = 3 and waitingtime < 50][
          set waitingtime waitingtime + 1
        ]
;         if waitingtime > 1600[
;          fd 0.015
;        ]
        if waitingtime > 3000[
          set status 0
        ]

      ] [
        set status 2
      ]
    ]

    ; Status 4: satiated, walk away
    if status = 4 [
      set color orange
      set firsttimeattack? false
      rt random-int-between -10 10
      fd 0.01
    ]
  ]
  ][
    ask lions [
      ; Status 0: relax, random walk before a alert
      if status = 0 [
        rt random-int-between -10 10
        ;fd 0.01
        ; Check for a possible alert
        let possiblewildebeest one-of wildebeests in-radius 50
        if possiblewildebeest != nobody and firsttimeattack? [
          ; if alert
          face possiblewildebeest
          set status 1
        ]
      ]
      ; Status 1: alerted, face the possible prey and slowly try to get near to it/them
      ; OBS: not a real ambush, cause when wildebeests migrate they're too much annd they also ignore more predators
      if status = 1 [
        ;; cerca uno gnu entro raggio 50
        let possiblewildebeest one-of wildebeests with [status = 1] in-radius 50
        ifelse possiblewildebeest != nobody and firsttimeattack? [
          ;; orientati verso lo gnu
          face possiblewildebeest
          fd 0.02
          ;; avanza lentamente solo se lo gnu è su acqua


          ;; se trovi uno gnu isolato (meno di 3 nel raggio 2) entro 12 passi, vai a targeting
          let probablewildebeest one-of wildebeests with [status = 1] in-radius 25
          if probablewildebeest != nobody and firsttimeattack? [
            face probablewildebeest
            set status 2
          ]
        ] [
          ;; se lo gnu è sparito, torna a relax
          set status 0
        ]
      ]
      ; Status 2: targeting mode, near to on or more target prey, wait until try to attack
      if status = 2 [
        ; try to attack (if exist a real target: wildebeest in radius 5 with only 1 neighbor)
        let prey one-of wildebeests in-radius 40
        ifelse prey != nobody and firsttimeattack? [
          ; Approach the target if is enough alone
          face prey
          fd 0.01
          set status 3
        ] [
          ;        ; Wait for attack
          set waitingtime waitingtime + 1
          let prey2 one-of wildebeests in-radius 5
          if prey2 = nobody [
            ; Prey no more killable --> wrong targeting
            set status 1
          ]
          if waitingtime > 100 [
            ; Impossible targeting, give up for the moment
            set status 1
            set waitingtime 0
          ]
        ]
      ]
      ; Status 3: try to kill
      if status = 3 [
        ; try to kill
        set lionsattacks (lionsattacks + 1)
        set waitingtime waitingtime + 1
        set color yellow
        ;; ------------------------------------------------------------------
        let base-speed       0.017         ;; velocità massima
        let slowdown-start   2000           ;; quanti tick restare al massimo
        let slowdown-end     2500          ;; tick in cui si raggiunge la minima
        let min-speed        0.005         ;; non scendere oltre questo

        let slow-factor 0
        if waitingtime > slowdown-start [
          set slow-factor (waitingtime - slowdown-start) /
          (slowdown-end   - slowdown-start)
          set slow-factor min list 1 slow-factor          ;; clamp 0‒1
        ]

        let speed max list min-speed (base-speed * (1 - slow-factor))
        fd speed
        ;; ---------------------------------------------------------
        let prey one-of wildebeests
        ifelse prey != nobody and firsttimeattack? [
          face prey
          fd speed
          if [distance myself] of prey < 1 [
            ; predation
            ask prey [ die ]
            set wildebeestseatenbylions wildebeestseatenbylions + 1
            set status 4
          ]

          while [status = 3 and waitingtime < 50][
            set waitingtime waitingtime + 1
          ]
          ;         if waitingtime > 1600[
          ;          fd 0.015
          ;        ]
          if waitingtime > 3000[
            set status 0
          ]

        ] [
          set status 2
        ]
      ]

      ; Status 4: satiated, walk away
      if status = 4 [
        set color orange
        set firsttimeattack? false
        rt random-int-between -10 10
        fd 0.01
      ]
    ]
  ]

end

to go-lionesses
  ; Una sola leonessa (la "leader") sceglie la preda
  let leader-lioness min-one-of lionesses [who]
  let target-prey one-of wildebeests
  if target-prey != nobody [

  ask lionesses [
    set group-target target-prey
  ]
]

ask lionesses [
    ;; prima di qualsiasi movimento, controllo il patch-ahead:
    if status = 0 [
      ;; cerco uno gnù in status 1 (vicino all'acqua) entro raggio 50
      let prey-lionesses one-of wildebeests in-radius 50 with [status = 1]
      if prey-lionesses != nobody [
        set status 1         ;; passo ad allerta
        face prey-lionesses
      ]
    ]


    ; Status 1: allertato, affronta la possibile preda e cerca di avvicinarsi lentamente
    if status = 1 [
      let possiblewildebeest one-of wildebeests in-radius 50
      ifelse possiblewildebeest != nobody [
        face possiblewildebeest
        fd 0.02
        ; Targeting della preda: controlla una probabile preda
        let probablewildebeest one-of wildebeests  in-radius 20
        if probablewildebeest != nobody [
          face probablewildebeest
          ask lionesses[
          set status 2
          ]
        ]
      ][
        ; falso allarme
        set status 0
      ]
    ]
    if status = 2 [
      set color green
      ifelse group-target != nobody and distance group-target < 40 [
        face group-target
        fd 0.01
        set status 3
      ] [
        set waitingtime waitingtime + 1
        if waitingtime > 100 [
          set status 1
          set waitingtime 0
        ]
      ]


;      if count wildebeests in-radius 3 > 3 [
;        rt 180
;        set status 4
;      ]


    ]
    ; Status 3: tenta di uccidere
    if status = 3 [
      ; tenta di uccidere
      set lionsattacks (lionsattacks + 1)
      set waitingtime waitingtime + 1

       ;; ------------------------------------------------------------------
      let base-speed       0.02         ;; velocità massima
      let slowdown-start   1500           ;; quanti tick restare al massimo
      let slowdown-end     2500          ;; tick in cui si raggiunge la minima
      let min-speed        0.005         ;; non scendere oltre questo

      let slow-factor 0
      if waitingtime > slowdown-start [
        set slow-factor (waitingtime - slowdown-start) /
        (slowdown-end   - slowdown-start)
        set slow-factor min list 1 slow-factor          ;; clamp 0‒1
      ]

      let speed max list min-speed (base-speed * (1 - slow-factor))
      fd speed
      ;; ---------------------------------------------------------

      ifelse group-target != nobody [
        ifelse not dead? group-target [
          face group-target
          fd speed
          if distance group-target < 1 [
            ask group-target [
              die
            ]
            ;; appena la preda muore, tutte le leonesse si fermano
            ask lionesses [
              set status 0
            ]
            set wildebeestseatenbylions wildebeestseatenbylions + 1
            set group-target nobody
            set status 4
          ]
        ] [
          ; la preda è già morta
          set group-target nobody
          set status 0
        ]
      ] [
        set status 2
      ]
    ]


    ; Status 4: sazio, allontanati
    if status = 4 [
      set color orange
    ]
  ]
end




; --------------------------- BOIDS / FLOCKING ------------------------------
to to-flock [a b c d]
  find-flockmates
  if any? flockmates [
    find-nearest-neighbor
    let minimum-separation a
    ifelse distance nearest-neighbor < minimum-separation
      [ separate b ]
      [ align c  cohere d ]
  ]
end

to find-flockmates
  let vision 8
  set flockmates other turtles with [breed = [breed] of myself] in-radius vision
end


to find-nearest-neighbor
  set nearest-neighbor min-one-of flockmates [distance myself]
end

to separate [mst]
  turn-away ([heading] of nearest-neighbor) mst
end

to align [mat]
  turn-towards average-flockmate-heading mat
end

to-report average-flockmate-heading
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to cohere [mct]
  turn-towards average-heading-towards-flockmates mct
end

to-report average-heading-towards-flockmates
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to turn-towards [new-heading max-turn]
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]
  ifelse abs turn > max-turn
    [ ifelse turn > 0 [ rt max-turn ] [ lt max-turn ] ]
    [ rt turn ]
end

; --------------------------- FUNZIONI DI SUPPORTO --------------------------
to-report random-int-between [min-num max-num]
  report random (max-num - min-num) + min-num
end

to-report on-water?
  report (shade-of? pcolor blue) or (shade-of? pcolor sky) or (shade-of? pcolor cyan)or (shade-of? pcolor grey)
end

to-report between-rivers?
  let margin 2
  report (not on-water?)
     and pycor < (upper-river - margin)
     and pycor > (lower-river + margin)
end


to-report on-depth-water?
  report (shade-of? pcolor blue)
end
to-report dead? [agent]
  report not member? agent turtles
end



;to-report random-box
;  let box-width  random (max-pxcor / 2) + 5   ; larghezza random (min 5)
;  let box-height random (max-pycor / 2) + 5   ; altezza random (min 5)
;
;  let min-x random (max-pxcor - box-width)
;  let min-y random (max-pycor - box-height)
;  let max-x min-x + box-width
;  let max-y min-y + box-height
;
;  report patches with [pxcor >= min-x and pxcor <= max-x and
;                       pycor >= min-y and pycor <= max-y]
;end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
695
496
-1
-1
1.98
1
10
1
1
1
0
0
0
1
-120
120
-120
120
0
0
1
ticks
30.0

SLIDER
0
10
172
43
wildebeests-number
wildebeests-number
0
100
46.0
1
1
NIL
HORIZONTAL

BUTTON
700
10
763
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
760
10
823
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
0
44
103
77
lions?
lions?
0
1
-1000

SLIDER
0
78
172
111
lions-number
lions-number
0
10
1.0
1
1
NIL
HORIZONTAL

SWITCH
0
184
120
217
high-grass
high-grass
0
1
-1000

SWITCH
0
114
106
147
lionesses?
lionesses?
1
1
-1000

SLIDER
0
151
121
184
lionesses-number
lionesses-number
2
6
3.0
1
1
NIL
HORIZONTAL

SWITCH
0
224
103
257
day
day
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

lion
false
0
Polygon -16777216 true false 47 133 55 131 55 133
Polygon -7500403 true true 298 194 287 197 270 191 262 193 262 205 280 226 280 257 273 265 262 266 260 260 269 253 269 230 240 206 232 198 225 209 234 228 235 243 218 261 216 268 200 267 197 261 223 239 221 231 200 207 202 196 181 201 157 202 140 195 134 210 128 213 127 238 133 251 140 248 146 265 131 264 122 247 114 240 102 260 100 271 83 271 81 262 93 258 105 230 108 198 90 184 73 164 58 144 41 145 16 151 23 141 7 140 1 134 3 127 27 119 30 105
Polygon -7500403 true true 301 195 286 180 264 166 260 153 247 140 218 131 166 133 141 126 112 115 73 108 64 102 62 98 32 86 31 92 19 87 31 103 31 113
Circle -7500403 true true 60 90 30
Circle -7500403 true true 39 114 42
Circle -7500403 true true 45 90 30
Circle -7500403 true true 45 75 30
Circle -7500403 true true 30 75 30
Circle -7500403 true true 15 75 30
Circle -7500403 true true 15 90 30
Circle -7500403 true true 15 105 30
Circle -7500403 true true 30 135 30
Circle -7500403 true true 45 135 30

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
