# Transcript: Atuin in about 6 minutes

**Video:** https://www.youtube.com/watch?v=JzVXK0WorpI
**Channel:** Jilles

---

[00:00] What's up, guys? It's another day and I
[00:01] have another tool. This one is so good
[00:03] that I forgot I use it every day because
[00:05] I'm just so used to using it. It's
[00:07] called atuin and it's a fuzzy searching
[00:10] tool for your shell history that also
[00:12] backs it up and adds AI features. Those
[00:14] Those are optional. Let's start with the
[00:16] problem. If I want to search my commands
[00:18] in the past, I would press command R and
[00:20] for example say get and then I can
[00:22] control R until I find the one that I
[00:25] like. And if I don't find it, then
[00:27] that's too bad. If I want to go back to
[00:29] my last commands, I press the up arrow
[00:31] until I get something that I wanted.
[00:33] What if we could make this experience
[00:36] much better? That's what we're going to
[00:37] do. Here we go, making your terminal
[00:39] magical. And as always, I'm going to
[00:41] copy the install command, paste it in my
[00:43] terminal.
[00:44] I would love to import my current shell
[00:45] history.
[00:47] So next, it asks you to sign up for an
[00:48] account. You don't have to do this and I
[00:50] didn't do this before. And then I bought
[00:52] a new MacBook and I lost all my shell
[00:54] history because I didn't back that up.
[00:56] So I would recommend doing it. It's
[00:58] end-to-end encrypted. Both It is
[01:00] optional. So I'm I'm just going to say
[01:01] yes. Then you have to go to the URL to
[01:03] log in.
[01:05] I'll authorize it. And if I go back, I
[01:07] get wrong encryption key because I
[01:09] already have an account set up from
[01:11] before. So you probably won't get this.
[01:13] Yes, I would love to use the AI
[01:14] features. We'll talk about it in a bit.
[01:15] And I would also like the search demon
[01:17] for improved search and history sync. So
[01:19] there are two ways to trigger atuin. The
[01:21] first one is just pressing control R.
[01:22] When I do, I get my global search. So
[01:25] this is any command I've ever typed.
[01:26] Then if I type get, I get everything
[01:28] with get. If I type pi, I get everything
[01:30] with pi. Pi heard or squat. I can press
[01:32] control R again to switch
[01:33] [clears throat]
[01:34] the search scope. So if I do it again,
[01:36] now it's host. Host is useful if you
[01:38] have multiple machines. Next, you have
[01:39] session. This is what I used in my
[01:41] current session. See, I only typed atuin
[01:43] sync and clear. Finally, there's
[01:45] directory, which is every command I did
[01:47] in this current directory. This is also
[01:50] what I will map to the up arrow. There's
[01:52] one more called workspace, which will be
[01:54] in a git workspace. So if you have a
[01:56] subfolder in a Git repository, you can
[01:58] see all the commands that were run in
[02:00] that repository. Now, there's also the
[02:02] search filter. So, by default, it's
[02:04] fuzzy. So, if I say GTDF
[02:07] for Git diff, you can see here it's Git
[02:09] diff. If I want something else, I can do
[02:11] Ctrl S. Now, it's prefix. Now, if I do
[02:13] Git, I get everything that started with
[02:15] Git. And finally, there's full text,
[02:17] which is similar to fuzzy, but actually
[02:19] matches the real word. So, if I do full
[02:21] text for finance, then I have my when I
[02:24] open file
[02:26] finances. And finally, it's the search
[02:28] demon. That's the fuzzy one that I
[02:29] showed earlier. That's the default. Now,
[02:31] next let me open up atuin and type
[02:32] config. There's some numbers on the
[02:34] left. If I want to go quickly to one of
[02:36] those, I actually want to do number
[02:37] four, vim config. I just press option
[02:40] four. Enter. Now, I have opened vim in
[02:42] this directory. I want to open up
[02:44] tommel, and there's a few settings I
[02:45] want to go over. The first one I would
[02:46] want to show you is this up arrow filter
[02:48] mode shell up key binding, this one
[02:50] right here. And to me, it's set to
[02:52] directory. So, that means that if I
[02:53] press the up arrow, it will filter by
[02:55] the current directory, similar to what
[02:57] it did before, but now with this nice to
[02:59] we. Close it, and I do the up arrow.
[03:01] This is everything I typed in here. As
[03:02] you can see, it's directory. The other
[03:04] thing I want to show you is the command.
[03:06] So, if I do Ctrl R, these are the
[03:07] commands. If I press enter, it runs the
[03:09] command. If I press tab, it shows it.
[03:11] Tab type CD pipe without running it, so
[03:14] I can do slash agent, and I can access
[03:15] it. If I do enter, I type enter, it
[03:18] actually runs the command. There is two
[03:20] settings I think you need to be aware
[03:21] of. There's the history filter, which is
[03:24] any command that matches this regular
[03:25] expression will not be stored in atuin
[03:28] history. And the other one is current
[03:29] working directory filter, which is any
[03:31] directory that matches this regex will
[03:33] not be restored. For example, you would
[03:34] add node modules or or something that
[03:36] for you is confidential. The other thing
[03:38] is if you don't like this full screen
[03:41] view, you can change the the line height
[03:44] in line height. If I set this to 10, let
[03:46] me clear it, and I Ctrl R. Now, you see
[03:48] it only shows me much less here. But I
[03:50] personally actually like full screen, so
[03:53] I'm leaving this commented out. So, we
[03:55] talked about the defaults, the
[03:57] workspace, the search functions. Now,
[03:58] let's talk about sync. So, if I do atuin
[04:00] sync,
[04:01] all those things I just ran are being
[04:04] sent to the database, which means that
[04:06] if I install a new computer or add
[04:07] another computer, it's all going to be
[04:09] here. You can actually also filter and
[04:11] see some more about this command. So, if
[04:13] I go to pi here, if I press control O, I
[04:16] actually get some details around it.
[04:19] Right, so which host was used, which
[04:21] user, when did I run this, duration over
[04:24] time. This is the error exit code
[04:26] distribution, and you can also use atuin
[04:28] AI [clears throat] to ask it questions
[04:30] like, "How often did I exit pi?" Right,
[04:33] I don't know if that's useful for you,
[04:34] but it's possible. The last thing I want
[04:35] to talk about is atuin AI. This is
[04:38] optional, and you can self-host it if
[04:41] you want. Look here, but I think it's
[04:43] cool to see. Atuin UI allows you to have
[04:46] AI in your shell, but also integrate
[04:48] well with your atuin history and just
[04:50] shell command. By default, it's question
[04:52] mark. Now, here you can see generate a
[04:53] command or ask a question. I can ask it
[04:55] here in this pi directory, "What was my
[04:57] latest git commit?" if I don't remember
[04:59] the command. So, I will say allow, and
[05:02] it says, "Your latest commit was at her
[05:03] desk." You can always also go back and
[05:05] forth. Let me do a question mark again.
[05:07] "How do I see current Docker containers
[05:09] running?" It will give a suggestion,
[05:11] then I can follow up. I also want to
[05:12] know the size of the container. Then it
[05:14] suggests this. So, if I now press enter,
[05:16] it will execute the suggested command.
[05:18] If I press tab, it will insert the
[05:20] command. So, let me do enter. I have no
[05:22] containers running, but this is how it
[05:24] will work. Thanks for watching. I hope
[05:25] this was useful, and you found something
[05:28] interesting here, and maybe you'll also
[05:29] be an atuin user. It's open source. You
[05:32] can self-host it. You can self-host the
[05:35] background sync and the AI tools. So, it
[05:37] really is a fantastic tool. Let me know
[05:39] in the comments what you thought, if you
[05:41] want to see another tool, any feedback,
[05:43] questions, suggestions, they're all
[05:45] welcome. And yeah, thanks again for
[05:47] watching. I appreciate it, and I'll see
[05:49] you all later.
