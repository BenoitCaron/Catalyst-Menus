//
//  AppDelegate.swift
//  POCMenuCatalyst
//
//  Created by Benoit Caron on 26/03/2020.
//  Copyright © 2020 bcn. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var isChecked = true
    var shouldShowHiddenMenu = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    /** Add the various menus to the menu bar.
        The system only asks UIApplication and UIApplicationDelegate for the main menus.
        Main menus appear regardless of who is in the responder chain.
    */
    override func buildMenu(with builder: UIMenuBuilder) {

        /** First check if the builder object is using the main system menu, which is the main menu bar.
            If you want to check if the builder is for a contextual menu, check for: UIMenuSystem.context
         */
        if builder.system == .main {
            // Then you can start building your menus

            // You can remove menus in the menu bar that you don't want, in our case the Format menu.
            builder.remove(menu: .format)

            // You can also remove submenus. Here, we remove the standard edit submenu (copy, paste, etc.)
            builder.remove(menu: .standardEdit)

            // You can add a new menu with insertSibling
            builder.insertSibling(newMenu(), afterMenu: .edit)

            // You can add a new entry in this menu with insertChild
            builder.insertChild(newItem(), atStartOfMenu: .newMenu)

            // You can also use insert a grouped menu
            builder.insertSibling(groupedSubmenu(), afterMenu: .newItem)

            // Now, lets add a menu which let us try UICommand's state and attributes properties
            builder.insertSibling(uiCommandMenu(), afterMenu: .newMenu)

            // Then, lets add a menu for which we're gonna try the different states
            builder.insertChild(stateMenu(), atEndOfMenu: .command)

            // Then, a menu for which we're gonna try the different attributes
            builder.insertSibling(attributeMenu(), afterMenu: .state)

            // As well as a dynamic menu
            builder.insertSibling(showHiddenMenuMenu(), afterMenu: .grouped)

            if shouldShowHiddenMenu {
                builder.insertSibling(hiddenMenu(), beforeMenu: .view)
            }
        }
    }

    override func validate(_ command: UICommand) {
        switch command.action {
        case #selector(noAction(_:)):
            guard let commandName = command.propertyList as? String else { return }
            switch commandName {
            case "currentStatusCommand":
                command.state = currentState
                switch currentState {
                case .on:
                    command.title = "Current state is .on"
                case .mixed:
                    command.title = "Current state is .mixed"
                case .off:
                    command.title = "Current state is .off"
                @unknown default:
                    break
                }
                command.attributes = currentAttributes
            default:
                break
            }
        case #selector(changeAttribute(_:)):
            guard let propertyList = command.propertyList as? [String: Any],
                let commandName = propertyList["command"] as? String else {
                    return
            }
            switch commandName {
            case "disabledCommand":
                command.state = currentAttributes.contains(.disabled) ? .on : .off
            case "destructiveCommand":
                command.state = currentAttributes.contains(.destructive) ? .on : .off
            case "hiddenCommand":
                command.state = currentAttributes.contains(.hidden) ? .on : .off
            default:
                break
            }
        case #selector(showHiddenMenu):
            command.state = shouldShowHiddenMenu ? .on : .off
        default:
            break
        }
    }

    @objc func noAction(_ sender: Any?) {
        print(#function)

        guard let command = sender as? UICommand,
            let propertyList = command.propertyList as? [String: Any],
            let commandName = propertyList["command"] as? String else {
                return
        }

        print("commandName: \(commandName)")
    }

    // MARK: - New menu

    func newMenu() -> UIMenu {
        let newMenu = UIMenu(title: "New menu",
                             image: nil,
                             identifier: .newMenu,
                             options: [],
                             children: [])
        return newMenu
    }

    // MARK: - New item

    func newItem() -> UIMenu {
        let alternateCommand = UICommandAlternate(title: "Secret command!",
                                                  action: #selector(noAction(_:)),
                                                  modifierFlags: [.command, .alternate])

        let newItemCommand = UIKeyCommand(title: "My first menu item",
                                          action: #selector(noAction(_:)),
                                          input: "I",
                                          modifierFlags: .command,
                                          propertyList: "newItemCommand",
                                          alternates: [alternateCommand])

        let inlineMenu = UIMenu(title: "",
                                identifier: .newItem,
                                options: .displayInline,
                                children: [newItemCommand])

        return inlineMenu
    }

    // MARK: - Grouped submenu

    func groupedSubmenu() -> UIMenu {
        let commands = (1...4).map { index in
            UIKeyCommand(title: "Item \(index)",
                action: #selector(noAction(_:)),
                input: String(index),
                modifierFlags: .command,
                propertyList: "groupedSubmenuCommand\(index)")
        }
        let groupedSubmenu = UIMenu(title: "Grouped submenu",
                                    image: #imageLiteral(resourceName: "commandImage.pdf"),
                                    identifier: .grouped,
                                    options: [],
                                    children: commands)

        return groupedSubmenu
    }

    // MARK: - UICommand menu

    func uiCommandMenu() -> UIMenu {
        let uiCommandCommand = UIKeyCommand(title: "Current status (will never appear though)",
                                            action: #selector(noAction(_:)),
                                            input: "P",
                                            modifierFlags: .command,
                                            propertyList: "currentStatusCommand")

        let uiCommandMenu = UIMenu(title: "Command properties",
                                   identifier: .command,
                                   options: [],
                                   children: [uiCommandCommand])

        return uiCommandMenu
    }

    // MARK: - State menu

    var currentState = UIMenuElement.State.off

    func stateMenu() -> UIMenu {
        let onCommand = UICommand(title: "Change state to .on",
                                            action: #selector(changeState(_:)),
                                            propertyList: UIMenuElement.State.on.rawValue)

        let mixedCommand = UICommand(title: "Change state to .mixed",
                                            action: #selector(changeState(_:)),
                                            propertyList: UIMenuElement.State.mixed.rawValue)

        let offCommand = UICommand(title: "Change state to .off",
                                            action: #selector(changeState(_:)),
                                            propertyList: UIMenuElement.State.off.rawValue)

        let stateMenu = UIMenu(title: "This title will not appear either",
                               identifier: .state,
                               options: .displayInline,
                               children: [onCommand, mixedCommand, offCommand])

        return stateMenu
    }

    @objc func changeState(_ sender: Any?) {
        print(#function)

        guard let command = sender as? UICommand,
            let rawValue = command.propertyList as? Int,
            let state = UIMenuElement.State(rawValue: rawValue) else {
                return
        }

        currentState = state
    }

    // MARK: - Attribute menu

    var currentAttributes: UIMenuElement.Attributes = []

    func attributeMenu() -> UIMenu {
        let disabledCommand = UICommand(title: "Disabled",
                                        action: #selector(changeAttribute(_:)),
                                        propertyList: ["command": "disabledCommand",
                                                       "newAttribute": UIMenuElement.Attributes.disabled.rawValue])

        let destructiveCommand = UICommand(title: "Destructive",
                                           action: #selector(changeAttribute(_:)),
                                           propertyList: ["command": "destructiveCommand",
                                                          "newAttribute": UIMenuElement.Attributes.destructive.rawValue])

        let hiddenCommand = UICommand(title: "Hidden",
                                      action: #selector(changeAttribute(_:)),
                                      propertyList: ["command": "hiddenCommand",
                                                     "newAttribute": UIMenuElement.Attributes.hidden.rawValue])

        let attributeMenu = UIMenu(title: "This title will not appear",
                                   identifier: .attribute,
                                   options: .displayInline,
                                   children: [disabledCommand, destructiveCommand, hiddenCommand])

        return attributeMenu
    }

    @objc func changeAttribute(_ sender: Any?) {
        print(#function)

        guard let command = sender as? UICommand,
            let propertyList = command.propertyList as? [String: Any],
            let rawValue = propertyList["newAttribute"] as? UInt
             else {
                return
        }
        let attribute = UIMenuElement.Attributes(rawValue: rawValue)

        currentAttributes.formSymmetricDifference(attribute)
    }

    // MARK: Hidden command menu

    func showHiddenMenuMenu() -> UIMenu {
        let showHiddenMenuCommand = UIKeyCommand(title: "Show hidden menu",
                                         action: #selector(showHiddenMenu),
                                         input: "H",
                                         modifierFlags: [.command, .shift])

        let hiddenCommandMenu = UIMenu(title: "" ,
                                       identifier: nil,
                                       options: .displayInline,
                                       children: [showHiddenMenuCommand])

        return hiddenCommandMenu
    }

    @objc func showHiddenMenu() {
        shouldShowHiddenMenu = !shouldShowHiddenMenu
        UIMenuSystem.main.setNeedsRebuild()
    }

    // MARK: Hidden menu

    func hiddenMenu() -> UIMenu {
        let hiddenMenuCommands = (1...Int.random(in: 1...10)).map { index in
            UIKeyCommand(title: "Random command \(index)",
                image: #imageLiteral(resourceName: "commandImage.pdf"),
                action: #selector(noAction(_:)),
                input: String(index),
                modifierFlags: [.command, .shift],
                propertyList: index)
        }

        let dynamicMenu =
            UIMenu(title: "Hidden menu" ,
                   identifier: nil,
                   options: [],
                   children: hiddenMenuCommands)

        return dynamicMenu
    }
}

extension UIMenu.Identifier {
    static var newMenu: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.newMenu") }
    static var newItem: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.newItem") }
    static var command: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.command") }
    static var state: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.state") }
    static var attribute: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.attribute") }
    static var grouped: UIMenu.Identifier { UIMenu.Identifier("com.bcn.POCMenuCatalyst.grouped") }
}
