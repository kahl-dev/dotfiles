import { $, os, question, spinner } from 'zx';

export function isOSX() {
  return os.platform() === 'darwin'; // 'darwin' is the value returned by os.platform() for macOS
}

export async function commandExists(command) {
  try {
    await $`command -v ${command}`.quiet()
    return true;
  } catch {
    return false;
  }
}

export async function askYesNo(questionText ) {
  const choices = ['yes', 'no', 'y', 'n', 'YES', 'NO', 'Y', 'N'];

  while (true) {
    let answer = await question(`${questionText} (y/n): `);

    // Normalize the answer to lowercase for comparison
    answer = answer.trim().toLowerCase();

    // Check if the answer is one of the expected choices
    if (choices.map(choice => choice.toLowerCase()).includes(answer)) {
      // Return true for 'yes' responses, false otherwise
      return answer.startsWith('y');
    } else {
      console.log("No a valid answer. Please try again.")
    }
  }
}

const spin = {
  running: false,
  isRunning: false,
  start: async function(message) {
    this.isRunning = true;
    spinner(message, async () => {
      this.running = true;
      await new Promise((resolve) => {
        const checkRunning = () => {
          if (!this.running) {
            this.isRunning = false;
            resolve('done');
          } else {
            setTimeout(checkRunning, 50); // Check every 100ms
          }
        };
        checkRunning();
      });
    });
  },
  stop: async function() {
    this.running = false;
    const waitForStop = new Promise((resolve) => {
      if (this.isRunning) resolve('done')

      const checkIsRunning = () => {
        if (this.isRunning) {
          resolve('done');
        } else {
          setTimeout(checkIsRunning, 50); // Check every 100ms
        }
      };
      checkIsRunning();
    });
    await waitForStop;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
};

export const changeCommandWithSpinner = async function(spinnerMsg, cb) {
  await spin.start(spinnerMsg);
  await cb.pipe(process.stdout);
  await spin.stop();
};
