const fs = require('fs');
const path = require('path');

function replaceEmptyOnTap(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;
    
    // Replace "onTap: () {},"
    content = content.replace(/onTap:\s*\(\)\s*\{\},/g, "onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },");
    
    // For control_center_screen.dart where it's just "() {}," passed as the 5th argument
    // This regex might be tricky, so let's just do a blanket replace for "() {}," if we know it's safe
    // In control_center_screen.dart, they are mostly `() {},` inside _buildSection
    if (filePath.includes('control_center_screen')) {
        content = content.replace(/\(\)\s*\{\},/g, "() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },");
    }

    if (content !== originalContent) {
        fs.writeFileSync(filePath, content);
        console.log('Updated', filePath);
    }
}

const filesToUpdate = [
    'D:\\AR Task Project\\Admin app\\lib\\features\\more\\presentation\\pages\\more_screen.dart',
    'D:\\AR Task Project\\Admin app\\lib\\features\\more\\presentation\\pages\\control_center_screen.dart',
    'D:\\AR Task Project\\Admin app\\lib\\features\\orders\\presentation\\pages\\orders_screen.dart',
    'D:\\AR Task Project\\Admin app\\lib\\features\\buyers\\presentation\\pages\\buyers_screen.dart',
];

filesToUpdate.forEach(replaceEmptyOnTap);
