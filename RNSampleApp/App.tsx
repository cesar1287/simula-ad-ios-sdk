import React, { useState } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  StatusBar,
} from 'react-native';
import { MiniGameProvider, MiniGameMenu } from 'simula-ad-sdk';

export default function App() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  // Define companion context messages
  const sampleMessages = [
    { role: 'user', content: 'Hey Luna! Do you want to play a game with me?' },
    { role: 'assistant', content: "I'd love to! I have some awesome games ready. Pick one from the menu below!" }
  ];

  return (
    <MiniGameProvider
      apiKey="pub_eeee14c661ce47659a289db29364723a"
      primaryUserID="user_react_native_demo_101"
      hasPrivacyConsent={true}
      devMode={false} // Disabled for production-session fallback ad redirects
    >
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={styles.container}>
        <View style={styles.cardContainer}>
          <Text style={styles.subtitle}>SIMULA AD SDK BRIDGE</Text>
          <Text style={styles.title}>Luna's Arcade</Text>
          <Text style={styles.description}>
            Experience native, programmatic in-app mini-games. Interact with the companion to discover immersive sponsored games and fallbacks, all staying completely inside the host app.
          </Text>

          <TouchableOpacity
            style={styles.button}
            onPress={() => {
              console.log('[App] Press: Opening Mini-Game Menu...');
              setIsMenuOpen(true);
            }}
            activeOpacity={0.8}
          >
            <Text style={styles.buttonText}>Play with Luna</Text>
          </TouchableOpacity>
        </View>

        <MiniGameMenu
          isOpen={isMenuOpen}
          charName="Luna"
          charID="char_luna_react_native"
          charImage="https://storage.googleapis.com/simula-public/assets/minigames/icons/boop-the-snoot-logo.png" // Fallback avatar image
          messages={sampleMessages}
          charDesc="Your friendly gaming AI companion"
          convId="conv_session_rn_992"
          entryPoint="home_arcade_card"
          maxGamesToShow={6}
          theme={{
            backgroundColor: '#0a0a0e',
            accentColor: '#00d2ff',
            titleFontColor: '#ffffff',
            borderColor: '#1d1d28',
            iconCornerRadius: 16
          }}
          delegateChar={true}
          showBanner={true}
          onGameOpen={(event) => {
            console.log('[Lifecycle Event] onGameOpen:', event.gameName, '-', event.description);
          }}
          onGameClose={(event) => {
            console.log('[Lifecycle Event] onGameClose:', event.gameName);
            setIsMenuOpen(false);
          }}
          onImpression={(event) => {
            console.log('[Lifecycle Event] onImpression (Catalog Loaded) menuId:', event.menuId);
          }}
          onDestinationOpen={(event) => {
            console.log('[Lifecycle Event] onDestinationOpen type:', event.destinationType, 'target:', event.target);
          }}
        />
      </SafeAreaView>
    </MiniGameProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#050508',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cardContainer: {
    width: '90%',
    padding: 24,
    borderRadius: 24,
    backgroundColor: '#0d0d14',
    borderWidth: 1,
    borderColor: '#181824',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.4,
    shadowRadius: 20,
    elevation: 8,
  },
  subtitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#00d2ff',
    letterSpacing: 2,
    marginBottom: 8,
  },
  title: {
    fontSize: 32,
    fontWeight: '900',
    color: '#ffffff',
    marginBottom: 16,
    textAlign: 'center',
  },
  description: {
    fontSize: 14,
    color: '#a0a0bc',
    lineHeight: 22,
    textAlign: 'center',
    marginBottom: 32,
  },
  button: {
    width: '100%',
    height: 56,
    borderRadius: 16,
    backgroundColor: '#00d2ff',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#00d2ff',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '800',
    color: '#050508',
    letterSpacing: 0.5,
  },
});
