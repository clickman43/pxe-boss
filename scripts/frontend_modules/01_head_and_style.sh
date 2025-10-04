#!/bin/bash
generate_head_and_style() {
cat <<'EOF'
<!DOCTYPE html>
<html lang="bg">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PXE-Boss Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .nav-link.active { background-color: #374151; color: #ffffff; } .nav-link.active svg { color: #3b82f6; }
        .no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        .toggle-checkbox:checked { background-color: #22c55e; }
        .toggle-checkbox:checked + .toggle-label { transform: translateX(100%); border-color: #22c55e; }
    </style>
</head>
<body class="bg-gray-100 font-sans antialiased">
EOF
}