'*
'* A simple wrapper around a slideshow. Single items and lists are both supported.
'*

Function createPhotoPlayerScreen(context, contextIndex, viewController)
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roSlideShow")
    screen.SetMessagePort(obj.Port)

    screen.SetUnderscan(2.5)
    screen.SetMaxUpscale(8.0)
    screen.SetDisplayMode("photo-fit")
    screen.SetPeriod(RegRead("slideshow_period", "preferences", "6").toInt())
    screen.SetTextOverlayHoldTime(RegRead("slideshow_overlay", "preferences", "2500").toInt())

    ' Standard screen properties
    obj.Screen = screen
    if type(context) = "roArray" then
        obj.Item = context[contextIndex]
        AddAccountHeaders(screen, obj.Item.server.AccessToken)
        screen.SetContentList(context)
        screen.SetNext(contextIndex, true)
        obj.CurIndex = contextIndex
        obj.PhotoCount = context.count()
    else
        obj.Item = context
        AddAccountHeaders(screen, obj.Item.server.AccessToken)
        screen.AddContent(context)
        screen.SetNext(0, true)
        obj.CurIndex = 0
        obj.PhotoCount = 1
    end if

    obj.HandleMessage = photoPlayerHandleMessage

    obj.Pause = photoPlayerPause
    obj.Resume = photoPlayerResume
    obj.Next = photoPlayerNext
    obj.Prev = photoPlayerPrev
    obj.Stop = photoPlayerStop

    obj.playbackTimer = createTimer()
    obj.IsPaused = false

    return obj
End Function

Function PhotoPlayer()
    ' If the active screen is a slideshow, return it. Otherwise, invalid.
    screen = GetViewController().screens.Peek()
    if type(screen.Screen) = "roSlideShow" then
        return screen
    else
        return invalid
    end if
End Function

Function photoPlayerHandleMessage(msg) As Boolean
    ' We don't actually need to do much of anything, the slideshow pretty much
    ' runs itself.

    handled = false

    if type(msg) = "roSlideShowEvent" then
        handled = true

        if msg.isScreenClosed() then
            ' Send an analytics event
            amountPlayed = m.playbackTimer.GetElapsedSeconds()
            Debug("Sending analytics event, appear to have watched slideshow for " + tostr(amountPlayed) + " seconds")
            AnalyticsTracker().TrackEvent("Playback", firstOf(m.Item.ContentType, "photo"), m.Item.mediaContainerIdentifier, amountPlayed)

            m.ViewController.PopScreen(m)
        else if msg.isPlaybackPosition() then
            m.CurIndex = msg.GetIndex()
        else if msg.isRequestFailed() then
            Debug("preload failed: " + tostr(msg.GetIndex()))
        else if msg.isRequestInterrupted() then
            Debug("preload interrupted: " + tostr(msg.GetIndex()))
        else if msg.isPaused() then
            Debug("paused")
        else if msg.isResumed() then
            Debug("resumed")
        end if
    end if

    return handled
End Function

Sub photoPlayerPause()
    if NOT m.IsPaused then
        m.Screen.Pause()
    end if
End Sub

Sub photoPlayerResume()
    if m.IsPaused then
        m.Screen.Resume()
    end if
End Sub

Sub photoPlayerNext()
    maxIndex = m.PhotoCount - 1
    index = m.CurIndex
    newIndex = index

    if index < maxIndex then
        newIndex = index + 1
    else
        newIndex = 0
    end if

    if index <> newIndex then
        m.Screen.SetNext(newIndex, true)
    end if
End Sub

Sub photoPlayerPrev()
    maxIndex = m.PhotoCount - 1
    index = m.CurIndex
    newIndex = index

    if index > 0 then
        newIndex = index - 1
    else
        newIndex = maxIndex
    end if

    if index <> newIndex then
        m.Screen.SetNext(newIndex, true)
    end if
End Sub

Sub photoPlayerStop()
    m.Screen.Close()
End Sub
