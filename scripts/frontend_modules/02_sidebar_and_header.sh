#!/bin/bash
generate_sidebar_and_header() {
cat <<'EOF'
    <div class="flex h-screen bg-gray-200">
        <aside class="w-64 bg-gray-800 text-gray-200 flex-shrink-0 no-scrollbar overflow-y-auto">
            <div class="p-6"> <h1 class="text-2xl font-bold text-white">PXE-Boss</h1> </div>
            <nav id="main-nav" class="px-3">
                <a href="#" data-view="dashboard" class="nav-link flex items-center py-2.5 px-4 rounded-md transition duration-200 hover:bg-gray-700 active"><svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path></svg> Dashboard</a>
                <a href="#" data-view="clients" class="nav-link flex items-center py-2.5 px-4 rounded-md transition duration-200 hover:bg-gray-700"><svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"></path></svg> Clients</a>
                <a href="#" data-view="images" class="nav-link flex items-center py-2.5 px-4 rounded-md transition duration-200 hover:bg-gray-700"><svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg> Images</a>
                <a href="#" data-view="admin" class="nav-link flex items-center py-2.5 px-4 rounded-md transition duration-200 hover:bg-gray-700"><svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg> Admin / Settings</a>
            </nav>
        </aside>
        <div class="flex-1 flex flex-col overflow-hidden">
            <header class="bg-white shadow-md p-4 flex justify-between items-center flex-shrink-0 text-sm">
                <div class="flex items-center space-x-4 text-gray-500">
                    <div><strong>Server Time:</strong> <span id="server-time" class="font-mono">...</span></div>
                    <div class="border-l border-gray-300 pl-4"><strong>System Uptime:</strong> <span id="system-uptime" class="font-mono">...</span></div>
                    <div class="border-l border-gray-300 pl-4"><strong>App Uptime:</strong> <span id="app-uptime" class="font-mono">...</span></div>
                </div>
                <button id="logoutButton" title="Logout" class="text-gray-500 hover:text-red-600"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path></svg></button>
            </header>
            <main class="flex-1 overflow-y-auto bg-gray-100 p-6 md:p-10">
EOF
}