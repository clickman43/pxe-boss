#!/bin/bash
generate_view_dashboard() {
cat <<'EOF'
                <div data-view-content="dashboard" class="view-content flex flex-col h-full">
                    <div class="flex-shrink-0">
                        <h2 class="text-3xl font-bold mb-6">Dashboard & Monitor</h2>
                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                            <div class="bg-white p-6 rounded-lg shadow"><h3 class="font-bold text-lg mb-2">Active Clients</h3><p id="stats-active-clients" class="text-3xl font-semibold">0</p></div>
                            <div class="bg-white p-6 rounded-lg shadow"><h3 class="font-bold text-lg mb-2">Images</h3><p id="stats-images" class="text-3xl font-semibold">0</p></div>
                            <div class="bg-white p-6 rounded-lg shadow"><h3 class="font-bold text-lg mb-2">Pending</h3><p id="stats-pending" class="text-3xl font-semibold">0</p></div>
                            <div class="bg-white p-6 rounded-lg shadow"><h3 class="font-bold text-lg mb-2">Alarms</h3><p id="stats-alarms" class="text-3xl font-semibold text-green-500">0</p></div>
                        </div>
                        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                            <div class="bg-white p-4 rounded-lg shadow"><div class="flex justify-between items-center mb-1"><span class="font-bold text-gray-700">CPU Usage</span><span id="cpu-percent-text" class="text-sm font-semibold">0%</span></div><div class="w-full bg-gray-200 rounded-full h-2.5"><div id="cpu-percent-bar" class="bg-blue-600 h-2.5 rounded-full" style="width: 0%"></div></div></div>
                            <div class="bg-white p-4 rounded-lg shadow"><div class="flex justify-between items-center mb-1"><span class="font-bold text-gray-700">Memory Usage</span><span id="ram-percent-text" class="text-sm font-semibold">0%</span></div><div class="w-full bg-gray-200 rounded-full h-2.5"><div id="ram-percent-bar" class="bg-green-600 h-2.5 rounded-full" style="width: 0%"></div></div></div>
                            <div class="bg-white p-4 rounded-lg shadow"><div class="flex justify-between items-center mb-1"><span class="font-bold text-gray-700">Disk Usage (/)</span><span id="disk-percent-text" class="text-sm font-semibold">0%</span></div><div class="w-full bg-gray-200 rounded-full h-2.5"><div id="disk-percent-bar" class="bg-yellow-500 h-2.5 rounded-full" style="width: 0%"></div></div></div>
                        </div>
                    </div>
                    <div class="bg-white p-6 rounded-lg shadow flex-1 flex flex-col overflow-hidden">
                        <h3 class="font-bold text-lg mb-4 flex-shrink-0">System Logs</h3>
                        <div id="logsContainer" class="text-xs font-mono bg-gray-900 text-green-400 p-4 rounded flex-1 overflow-y-auto no-scrollbar"></div>
                    </div>
                </div>
EOF
}