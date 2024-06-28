import { roboto_mono } from "@/app/components/fonts";
import Link from "next/link";

export default function Home() {
  return (
    <div>
      <div className="w-full h-[650px] overflow-hidden flex justify-center items-center bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500">
        <h1
          className={`${roboto_mono.className} absolute text-white uppercase text-9xl pl-20 drop-shadow-lg font-bold`}
        >
          Attend concerts via{" "}
          <span className="bg-gradient-to-r from-yellow-300 to-pink-300 hover:from-blue-300 hover:to-green-300 bg-clip-text text-transparent">
            web3
          </span>
        </h1>
        {/* <iframe
          title="Pori Jazz intro video"
          className="h-[140%] w-full"
          src="https://player.vimeo.com/video/912867382?badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479&amp;background=1&amp;autoplay=1&amp;loop=1&amp;byline=0&amp;title=0"
          allow="autoplay; fullscreen; picture-in-picture"
          aria-hidden="true"
          loading="lazy"
          frameBorder="0"
          allowFullScreen
        ></iframe> */}

        <video preload="metadata" autoPlay muted playsInline loop>
          <source src="/7722221-uhd_3840_2160_25fps.mp4" type="video/mp4" />
          Your browser does not support the video tag.
        </video>
      </div>

      <main className="grid grid-cols-2">
        <div className="h-[378px] bg-orange-500 text-white flex flex-col items-center justify-center p-8">
          <h1 className="text-3xl font-bold">
            Pori Jazz announces first artists for summer 2024!
          </h1>
          <button className="mt-4 bg-white text-orange-500 font-bold py-2 px-8 rounded-full uppercase">
            READ MORE
          </button>
        </div>

        <div className="h-[378px] bg-blue-700 text-white flex flex-col items-center justify-center">
          <img
            src="https://content.porijazz.fi/wp-content/uploads/2024/02/verkkosivukuvat-2000x1000-jason-derulo-19-7-1024x512.jpg"
            alt="Art"
            className="w-full h-full object-cover"
          />
        </div>

        <div className=" h-[378px] bg-green-400 text-white flex flex-col items-center justify-center">
          <img
            src="https://content.porijazz.fi/wp-content/uploads/2024/02/porijazz2024-yleiso-box.jpg"
            alt="Art"
            className="w-full h-full object-cover"
          />
        </div>

        <div className="h-[378px] bg-purple-700 text-white flex flex-col items-center justify-center p-8">
          <h1 className="text-3xl font-bold">
            It’s all about environmental and social responsibility.
          </h1>
          <button className="mt-4 bg-white text-purple-700 font-bold py-2 px-8 rounded-full uppercase">
            Find out more!
          </button>
        </div>

        <div className="h-[378px] bg-red-500 text-white flex flex-col items-center justify-center p-8">
          <h1 className="text-3xl font-bold">
            Subscribe our newsletter and stay tuned!
          </h1>
          <button className="mt-4 bg-white text-red-500 font-bold py-2 px-8 rounded-full uppercase">
            SUBSCRIBE NOW!
          </button>
        </div>

        <div className="h-[378px] bg-yellow-500 text-white flex flex-col items-center justify-center">
          <img
            src="https://s1.s.tmol.io/static/98b3ba2cb0ebe59c335a7710a7367bc5.jpg"
            alt="People enjoying the festival"
            className="w-full h-full object-cover"
          />
        </div>
      </main>

      <main className="flex justify-center items-center h-[480px] mx-auto py-10 bg-[url('https://content.porijazz.fi/wp-content/uploads/2023/10/hashtag-2024-iso.jpg')]">
        <section>
          <h1 className=" text-9xl font-bold mb-6 text-center text-white drop-shadow-lg">
            Get Your Tickets
          </h1>
          <div className="text-center mt-20">
            <Link
              href="/concerts"
              className="text-3xl font-bold text-white py-4 px-16  transition duration-200 rounded-full uppercase bg-gradient-to-r from-yellow-500 to-pink-500 hover:from-yellow-400 hover:to-pink-400 shadow-lg"
            >
              Buy Tickets
            </Link>
          </div>
        </section>
      </main>
    </div>
  );
}
