#!/bin/bash
generate_view_clients() {
cat <<'EOF'
                <div data-view-content="clients" class="view-content hidden">
                    <h2 class="text-3xl font-bold mb-6">Clients Management</h2>
                    <div class="mb-8">
                        <h3 class="text-xl font-semibold mb-4 text-gray-700">Pending Clients</h3>
                        <div class="bg-white p-6 rounded-lg shadow overflow-x-auto">
                            <table class="min-w-full divide-y divide-gray-200"><thead class="bg-gray-50"><tr><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">MAC Address</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Seen</th><th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th></tr></thead>
                                <tbody id="pending-clients-table" class="bg-white divide-y divide-gray-200"></tbody>
                            </table>
                        </div>
                    </div>
                    <div>
                        <div class="flex justify-between items-center mb-4">
                            <h3 class="text-xl font-semibold text-gray-700">Registered Clients</h3>
                            <button id="add-client-btn" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center"><svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>Add Client</button>
                        </div>
                        <div class="bg-white p-6 rounded-lg shadow overflow-x-auto">
                            <table class="min-w-full divide-y divide-gray-200"><thead class="bg-gray-50"><tr><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">MAC Address</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">OS Image</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th><th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th></tr></thead>
                                <tbody id="registered-clients-table" class="bg-white divide-y divide-gray-200"></tbody>
                            </table>
                        </div>
                    </div>
                </div>
EOF
}