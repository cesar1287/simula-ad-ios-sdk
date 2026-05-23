import React from 'react';
import { Text } from 'react-native';
import ReactTestRenderer from 'react-test-renderer';

// Mock react-native and redefine NativeModules to bypass frozen descriptors safely
jest.mock('react-native', () => {
  const RN = jest.requireActual('react-native');
  
  const originalNativeModules = RN.NativeModules;
  const mockedNativeModules = Object.create(originalNativeModules);
  
  mockedNativeModules.SimulaAdSDK = {
    configure: jest.fn(),
  };
  
  Object.defineProperty(RN, 'NativeModules', {
    value: mockedNativeModules,
    writable: true,
    configurable: true,
  });
  
  return RN;
});

// Import the package and NativeModules after mock definition
import { MiniGameProvider, MiniGameMenu } from 'simula-ad-sdk';
import { NativeModules } from 'react-native';

describe('SimulaAdSDK React Native Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // Test 1: Verify Provider initializes native module successfully on mount
  test('MiniGameProvider successfully calls native configure on mount', async () => {
    await ReactTestRenderer.act(() => {
      ReactTestRenderer.create(
        <MiniGameProvider
          apiKey="test_pub_key_123"
          primaryUserID="user_99"
          hasPrivacyConsent={true}
          devMode={true}
          appDomain="testgames.com"
        >
          <Text>Arcade Shell</Text>
        </MiniGameProvider>
      );
    });

    // Verify native configure was dispatched with exact parameters
    expect(NativeModules.SimulaAdSDK.configure).toHaveBeenCalledTimes(1);
    expect(NativeModules.SimulaAdSDK.configure).toHaveBeenCalledWith(
      'test_pub_key_123',
      'user_99',
      true,
      true,
      'testgames.com'
    );
  });

  // Test 2: Verify Menu overlay returns null when closed to avoid rendering overhead
  test('MiniGameMenu returns null when isOpen is false', async () => {
    let component: any = null;
    await ReactTestRenderer.act(() => {
      component = ReactTestRenderer.create(
        <MiniGameMenu
          isOpen={false}
          charName="Luna"
          charID="luna"
          charImage="https://example.com/luna.png"
        />
      );
    });

    expect(component.toJSON()).toBeNull();
  });

  // Test 3: Verify Menu overlay instantiates Native component when isOpen is true
  test('MiniGameMenu instantiates Native UI component when isOpen is true', async () => {
    let component: any = null;
    await ReactTestRenderer.act(() => {
      component = ReactTestRenderer.create(
        <MiniGameMenu
          isOpen={true}
          charName="Luna"
          charID="luna"
          charImage="https://example.com/luna.png"
        />
      );
    });

    const json = component.toJSON();
    expect(json).not.toBeNull();
    // Native view manager should register and mount SimulaMiniGameMenu in JSON
    expect(json?.type).toBe('SimulaMiniGameMenu');
    expect(json?.props.isOpen).toBe(true);
    expect(json?.props.charName).toBe('Luna');
    expect(json?.props.style).toBeDefined();
  });

  // Test 4: Verify that event callbacks correctly forward unpacked native synthetic events to JS handlers
  test('MiniGameMenu correctly unpacks and triggers callback events', async () => {
    const spyGameOpen = jest.fn();
    const spyGameClose = jest.fn();
    const spyImpression = jest.fn();
    const spyDestinationOpen = jest.fn();

    let component: any = null;
    await ReactTestRenderer.act(() => {
      component = ReactTestRenderer.create(
        <MiniGameMenu
          isOpen={true}
          charName="Luna"
          charID="luna"
          charImage="https://example.com/luna.png"
          onGameOpen={spyGameOpen}
          onGameClose={spyGameClose}
          onImpression={spyImpression}
          onDestinationOpen={spyDestinationOpen}
        />
      );
    });

    const root = component.root;
    const nativeMenu = root.findByType('SimulaMiniGameMenu');

    // Simulate Native event triggers (which emit RCTDirectEventBlock nativeEvent structures)
    await ReactTestRenderer.act(() => {
      nativeMenu.props.onGameOpen({ nativeEvent: { gameName: 'Roblox Obby', description: 'Fun platformer' } });
      nativeMenu.props.onGameClose({ nativeEvent: { gameName: 'Roblox Obby' } });
      nativeMenu.props.onImpression({ nativeEvent: { menuId: 'menu_arcade_01' } });
      nativeMenu.props.onDestinationOpen({ nativeEvent: { destinationType: 'app', target: '831515428' } });
    });

    // Assert that the unpacked nativeEvent payload was correctly forwarded to JS handlers
    expect(spyGameOpen).toHaveBeenCalledTimes(1);
    expect(spyGameOpen).toHaveBeenCalledWith({ gameName: 'Roblox Obby', description: 'Fun platformer' });

    expect(spyGameClose).toHaveBeenCalledTimes(1);
    expect(spyGameClose).toHaveBeenCalledWith({ gameName: 'Roblox Obby' });

    expect(spyImpression).toHaveBeenCalledTimes(1);
    expect(spyImpression).toHaveBeenCalledWith({ menuId: 'menu_arcade_01' });

    expect(spyDestinationOpen).toHaveBeenCalledTimes(1);
    expect(spyDestinationOpen).toHaveBeenCalledWith({ destinationType: 'app', target: '831515428' });
  });

  // Test 5: Verify default props resolve correctly and custom theme parameters propagate
  test('MiniGameMenu resolves default props and maps custom style/theme parameters', async () => {
    let component: any = null;
    await ReactTestRenderer.act(() => {
      component = ReactTestRenderer.create(
        <MiniGameMenu
          isOpen={true}
          charName="Luna"
          charID="luna"
          charImage="https://example.com/luna.png"
          theme={{
            backgroundColor: '#0c0c12',
            accentColor: '#fe007f',
            iconCornerRadius: 24,
          }}
        />
      );
    });

    const root = component.root;
    const nativeMenu = root.findByType('SimulaMiniGameMenu');

    // Assert defaults
    expect(nativeMenu.props.maxGamesToShow).toBe(6);
    expect(nativeMenu.props.delegateChar).toBe(true);
    expect(nativeMenu.props.showBanner).toBe(true);

    // Assert customized theme
    expect(nativeMenu.props.theme).toEqual({
      backgroundColor: '#0c0c12',
      accentColor: '#fe007f',
      iconCornerRadius: 24,
    });
  });
});
