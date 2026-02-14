#!/usr/bin/env python3

"""
冰阅 数据管理和分析工具
=======================

支持书源导入、验证、分析等功能
"""

import json
import xml.etree.ElementTree as ET
import argparse
import sys
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from datetime import datetime

@dataclass
class BookSource:
    """书源数据结构"""
    id: str
    name: str
    url: str
    enabled: bool = True
    priority: int = 1
    last_updated: Optional[str] = None

class SourceManager:
    """书源管理器"""
    
    def __init__(self, data_file: str = "sources.json"):
        self.data_file = Path(data_file)
        self.sources: List[BookSource] = []
        self.load_sources()
    
    def load_sources(self) -> None:
        """加载书源"""
        if self.data_file.exists():
            try:
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        self.sources = [BookSource(**s) for s in data]
                    elif isinstance(data, dict) and 'sources' in data:
                        self.sources = [BookSource(**s) for s in data['sources']]
                print(f"✓ 加载了 {len(self.sources)} 个书源")
            except json.JSONDecodeError as e:
                print(f"错误: 无法解析 JSON - {e}")
                self.sources = []
    
    def save_sources(self) -> None:
        """保存书源"""
        with open(self.data_file, 'w', encoding='utf-8') as f:
            data = [asdict(s) for s in self.sources]
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✓ 保存了 {len(self.sources)} 个书源")
    
    def add_source(self, name: str, url: str, priority: int = 1) -> None:
        """添加书源"""
        source = BookSource(
            id=f"source_{len(self.sources)}_{datetime.now().timestamp()}",
            name=name,
            url=url,
            priority=priority,
            last_updated=datetime.now().isoformat()
        )
        self.sources.append(source)
        print(f"✓ 添加书源: {name}")
    
    def remove_source(self, name_or_id: str) -> None:
        """删除书源"""
        original_count = len(self.sources)
        self.sources = [s for s in self.sources 
                       if s.name != name_or_id and s.id != name_or_id]
        
        if len(self.sources) < original_count:
            print(f"✓ 删除书源: {name_or_id}")
        else:
            print(f"✗ 未找到书源: {name_or_id}")
    
    def list_sources(self) -> None:
        """列出所有书源"""
        if not self.sources:
            print("暂无书源")
            return
        
        print(f"\n{'ID':<30} {'名称':<20} {'优先级':<5} {'状态':<5}")
        print("-" * 60)
        
        for source in self.sources:
            status = "✓" if source.enabled else "✗"
            print(f"{source.id:<30} {source.name:<20} {source.priority:<5} {status:<5}")
    
    def validate_sources(self) -> Dict[str, int]:
        """验证书源"""
        stats = {
            "total": len(self.sources),
            "valid": 0,
            "invalid": 0,
            "duplicate_urls": 0
        }
        
        urls = {}
        
        for source in self.sources:
            # 检查基本字段
            if source.name and source.url:
                stats["valid"] += 1
                
                # 检查URL重复
                if source.url in urls:
                    stats["duplicate_urls"] += 1
                else:
                    urls[source.url] = source.name
            else:
                stats["invalid"] += 1
        
        return stats
    
    def export_to_xml(self, output_file: str) -> None:
        """导出为 XML"""
        root = ET.Element("sources")
        
        for source in self.sources:
            source_elem = ET.SubElement(root, "source")
            ET.SubElement(source_elem, "id").text = source.id
            ET.SubElement(source_elem, "name").text = source.name
            ET.SubElement(source_elem, "url").text = source.url
            ET.SubElement(source_elem, "enabled").text = str(source.enabled)
            ET.SubElement(source_elem, "priority").text = str(source.priority)
        
        tree = ET.ElementTree(root)
        tree.write(output_file, encoding='utf-8', xml_declaration=True)
        print(f"✓ 导出为 XML: {output_file}")
    
    def import_json(self, input_file: str) -> None:
        """从 JSON 导入"""
        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
                # 处理不同格式
                if isinstance(data, list):
                    items = data
                elif isinstance(data, dict):
                    items = data.get('sources', data.get('list', []))
                else:
                    print("错误: 无效的 JSON 格式")
                    return
                
                count = 0
                for item in items:
                    name = item.get('name') or item.get('title')
                    url = item.get('url') or item.get('link')
                    if name and url:
                        self.add_source(name, url, item.get('priority', 1))
                        count += 1
                
                print(f"✓ 从 JSON 导入了 {count} 个书源")
        
        except Exception as e:
            print(f"错误: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="冰阅 书源管理工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python source_manager.py --list                    # 列出所有书源
  python source_manager.py --add "笔趣阁" "http://..." # 添加书源
  python source_manager.py --remove "笔趣阁"          # 删除书源
  python source_manager.py --validate                # 验证书源
  python source_manager.py --export xml output.xml   # 导出为 XML
  python source_manager.py --import json input.json  # 从 JSON 导入
        """
    )
    
    parser.add_argument("--file", "-f", default="sources.json",
                       help="书源数据文件")
    parser.add_argument("--list", "-l", action="store_true",
                       help="列出所有书源")
    parser.add_argument("--add", "-a", nargs=2, metavar=("NAME", "URL"),
                       help="添加书源")
    parser.add_argument("--remove", "-r", metavar="NAME",
                       help="删除书源")
    parser.add_argument("--validate", "-v", action="store_true",
                       help="验证书源")
    parser.add_argument("--export", "-e", nargs=2, 
                       metavar=("FORMAT", "OUTPUT"),
                       help="导出书源 (格式: json, xml)")
    parser.add_argument("--import", "-i", nargs=2, metavar=("FORMAT", "INPUT"),
                       dest="import_data",
                       help="导入书源 (格式: json)")
    
    args = parser.parse_args()
    
    manager = SourceManager(args.file)
    
    if args.list:
        manager.list_sources()
    
    if args.add:
        manager.add_source(args.add[0], args.add[1])
        manager.save_sources()
    
    if args.remove:
        manager.remove_source(args.remove)
        manager.save_sources()
    
    if args.validate:
        stats = manager.validate_sources()
        print("\n书源验证结果:")
        print(f"  总数: {stats['total']}")
        print(f"  有效: {stats['valid']}")
        print(f"  无效: {stats['invalid']}")
        print(f"  重复 URL: {stats['duplicate_urls']}")
    
    if args.export:
        fmt, output = args.export
        if fmt.lower() == 'xml':
            manager.export_to_xml(output)
        else:
            print(f"不支持的格式: {fmt}")
    
    if args.import_data:
        fmt, input_file = args.import_data
        if fmt.lower() == 'json':
            manager.import_json(input_file)
            manager.save_sources()
        else:
            print(f"不支持的格式: {fmt}")

if __name__ == "__main__":
    main()
